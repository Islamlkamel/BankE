using System;
using System.IO;
using System.Threading.Tasks;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Stripe;

namespace BankE.API.Controllers
{
    [ApiController]
    [Route("api/webhooks/stripe")]
    public class StripeWebhookController : ControllerBase
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IConfiguration _configuration;
        private readonly ILogger<StripeWebhookController> _logger;

        public StripeWebhookController(
            IUnitOfWork unitOfWork,
            IConfiguration configuration,
            ILogger<StripeWebhookController> logger)
        {
            _unitOfWork = unitOfWork;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpPost]
        public async Task<IActionResult> HandleWebhook()
        {
            var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
            var signatureHeader = Request.Headers["Stripe-Signature"];
            var webhookSecret = _configuration["Stripe:WebhookSecret"];

            Event stripeEvent;
            try
            {
                stripeEvent = EventUtility.ConstructEvent(json, signatureHeader, webhookSecret);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Stripe webhook signature verification failed.");
                return BadRequest("Invalid signature");
            }

            _logger.LogInformation($"Received Stripe Webhook Event: {stripeEvent.Type}");

            if (stripeEvent.Type == "issuing_authorization.request")
            {
                var auth = stripeEvent.Data.Object as Stripe.Issuing.Authorization;
                if (auth == null) return BadRequest("Invalid authorization object");

                // Find card in our database
                var stripeCardId = auth.Card.Id;
                var cards = await _unitOfWork.Cards.FindAsync(c => c.StripeCardId == stripeCardId);
                var card = cards.FirstOrDefault();

                if (card == null)
                {
                    _logger.LogWarning($"Authorization declined: Card {stripeCardId} not found in BankE.");
                    return Ok(new { approved = false });
                }

                if (card.IsFrozen || card.Status != "active")
                {
                    _logger.LogWarning($"Authorization declined: Card {stripeCardId} is inactive or frozen.");
                    return Ok(new { approved = false });
                }

                // Check wallet balance (Stripe amounts are in cents, convert to dollars/main currency unit)
                var amountInDollars = (decimal)auth.Amount / 100m;
                var account = await _unitOfWork.Accounts.GetByIdAsync(card.AccountId);

                if (account == null || account.Balance < amountInDollars)
                {
                    _logger.LogWarning($"Authorization declined: Account balance too low or account not found.");
                    return Ok(new { approved = false });
                }

                // Authorize transaction (hold/deduct funds)
                account.Balance -= amountInDollars;
                
                // Add a pending transaction log
                var transaction = new Transaction
                {
                    SenderAccountId = account.Id,
                    ReceiverAccountId = account.Id, // Self transaction/Merchant charge
                    Amount = amountInDollars,
                    Description = $"{auth.MerchantData.Name} ({auth.MerchantData.City})",
                    Status = "Pending",
                    CreatedAt = DateTime.UtcNow
                };

                await _unitOfWork.Transactions.AddAsync(transaction);
                await _unitOfWork.SaveChangesAsync();

                _logger.LogInformation($"Authorization approved for card {stripeCardId}: {amountInDollars} USD.");
                return Ok(new { approved = true });
            }
            else if (stripeEvent.Type == "issuing_transaction.created")
            {
                var stripeTx = stripeEvent.Data.Object as Stripe.Issuing.Transaction;
                if (stripeTx == null) return BadRequest("Invalid transaction object");

                // Settle/Finalize transaction in BankE
                var stripeCardId = stripeTx.CardId;
                var cards = await _unitOfWork.Cards.FindAsync(c => c.StripeCardId == stripeCardId);
                var card = cards.FirstOrDefault();

                if (card != null)
                {
                    var amountInDollars = (decimal)Math.Abs(stripeTx.Amount) / 100m;
                    // Find the pending transaction and update its status
                    var pendingTxs = await _unitOfWork.Transactions.FindAsync(t => 
                        t.SenderAccountId == card.AccountId && 
                        t.Amount == amountInDollars && 
                        t.Status == "Pending"
                    );

                    var tx = pendingTxs.FirstOrDefault();
                    if (tx != null)
                    {
                        tx.Status = "Completed";
                        await _unitOfWork.SaveChangesAsync();
                        _logger.LogInformation($"Settle successful for BankE transaction ID {tx.Id}.");
                    }
                }
            }

            return Ok();
        }
    }
}
