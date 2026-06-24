using BankE.Application.Common;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using BankE.Domain.Entities;
using BankE.Domain.Interfaces;

namespace BankE.Application.Services
{
    public class CardsService : ICardsService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly IStripeIssuingService _stripeIssuingService;

        public CardsService(IUnitOfWork unitOfWork, IStripeIssuingService stripeIssuingService)
        {
            _unitOfWork = unitOfWork;
            _stripeIssuingService = stripeIssuingService;
        }

        public async Task<ApiResponse<IEnumerable<CardResponse>>> GetCardsAsync(int userId)
        {
            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);
            if (account == null) return ApiResponse<IEnumerable<CardResponse>>.Fail("Account not found");

            var cards = await _unitOfWork.Cards.FindAsync(c => c.AccountId == account.Id);
            return ApiResponse<IEnumerable<CardResponse>>.Ok(cards.Select(c => new CardResponse(
                c.Id, 
                c.StripeCardId, 
                c.CardNumber,
                c.Cvv,
                c.Last4, 
                c.Brand, 
                c.ExpiryMonth, 
                c.ExpiryYear, 
                c.CardHolderName, 
                c.CardType, 
                c.Status, 
                c.IsFrozen, 
                c.IsVirtual)));
        }

        public async Task<ApiResponse<CardResponse>> AddCardAsync(int userId, AddCardRequest request)
        {
            var account = await _unitOfWork.Accounts.GetByUserIdAsync(userId);
            if (account == null) return ApiResponse<CardResponse>.Fail("Account not found");

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null) return ApiResponse<CardResponse>.Fail("User not found");

            // Create card on Stripe sandbox
            StripeCardModel stripeCard;
            try
            {
                stripeCard = await _stripeIssuingService.CreateCardAsync(user.FullName, user.Email, request.CardType);
            }
            catch (System.Exception ex)
            {
                return ApiResponse<CardResponse>.Fail($"Failed to create Stripe card: {ex.Message}");
            }

            var card = new Card
            {
                AccountId = account.Id,
                StripeCardId = stripeCard.StripeCardId,
                CardNumber = stripeCard.CardNumber,
                Cvv = stripeCard.Cvv,
                Last4 = stripeCard.Last4,
                Brand = stripeCard.Brand,
                ExpiryMonth = stripeCard.ExpiryMonth,
                ExpiryYear = stripeCard.ExpiryYear,
                CardHolderName = stripeCard.CardHolderName,
                CardType = request.CardType,
                Status = stripeCard.Status,
                IsVirtual = request.IsVirtual,
                IsFrozen = false
            };

            await _unitOfWork.Cards.AddAsync(card);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<CardResponse>.Ok(new CardResponse(
                card.Id, 
                card.StripeCardId, 
                card.CardNumber,
                card.Cvv,
                card.Last4, 
                card.Brand, 
                card.ExpiryMonth, 
                card.ExpiryYear, 
                card.CardHolderName, 
                card.CardType, 
                card.Status, 
                card.IsFrozen, 
                card.IsVirtual));
        }

        public async Task<ApiResponse> ToggleFreezeAsync(int userId, int cardId)
        {
            var card = await _unitOfWork.Cards.GetByIdAsync(cardId);
            if (card == null) return ApiResponse.Fail("Card not found");

            try
            {
                if (card.IsFrozen)
                {
                    card.Status = await _stripeIssuingService.UnfreezeCardAsync(card.StripeCardId);
                    card.IsFrozen = false;
                }
                else
                {
                    card.Status = await _stripeIssuingService.FreezeCardAsync(card.StripeCardId);
                    card.IsFrozen = true;
                }
            }
            catch (System.Exception ex)
            {
                return ApiResponse.Fail($"Failed to update card status on Stripe: {ex.Message}");
            }

            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok(card.IsFrozen ? "Card frozen successfully" : "Card unfrozen successfully");
        }

        public async Task<ApiResponse> DeleteCardAsync(int userId, int cardId)
        {
            var card = await _unitOfWork.Cards.GetByIdAsync(cardId);
            if (card == null) return ApiResponse.Fail("Card not found");

            // Stripe cards cannot be deleted, but we can permanently cancel them (set status to 'canceled')
            try
            {
                await _stripeIssuingService.CancelCardAsync(card.StripeCardId);
            }
            catch (System.Exception)
            {
                // Soft fail on external cancel, proceed with DB delete
            }

            _unitOfWork.Cards.Remove(card);
            await _unitOfWork.SaveChangesAsync();
            return ApiResponse.Ok("Card deleted successfully");
        }
    }
}
