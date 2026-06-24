using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using BankE.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Stripe;
using Stripe.Issuing;

namespace BankE.Infrastructure.Services
{
    public class StripeIssuingService : IStripeIssuingService
    {
        public StripeIssuingService(IConfiguration configuration)
        {
            StripeConfiguration.ApiKey = configuration["Stripe:SecretKey"];
        }

        private async Task<Cardholder> GetOrCreateCardholderAsync(string name, string email)
        {
            var cardholderService = new CardholderService();
            
            // Try to find existing cardholder by email
            var listOptions = new CardholderListOptions { Email = email, Limit = 1 };
            var existing = await cardholderService.ListAsync(listOptions);
            var cardholder = existing.FirstOrDefault();

            // Create new cardholder for sandbox
            var firstName = name.Split(' ')[0];
            var lastName = name.Contains(' ') ? name.Substring(name.IndexOf(' ') + 1) : "User";

            var createOptions = new CardholderCreateOptions
            {
                Type = "individual",
                Name = name,
                Email = email,
                PhoneNumber = "+15555555555",
                Individual = new CardholderIndividualOptions
                {
                    FirstName = firstName,
                    LastName = lastName,
                    Dob = new CardholderIndividualDobOptions
                    {
                        Day = 1,
                        Month = 1,
                        Year = 1990
                    },
                    CardIssuing = new CardholderIndividualCardIssuingOptions
                    {
                        UserTermsAcceptance = new CardholderIndividualCardIssuingUserTermsAcceptanceOptions
                        {
                            Date = DateTime.UtcNow,
                            Ip = "192.168.1.1",
                            UserAgent = "Mozilla/5.0"
                        }
                    }
                },
                Billing = new CardholderBillingOptions
                {
                    Address = new AddressOptions
                    {
                        Line1 = "123 Main St",
                        City = "San Francisco",
                        State = "CA",
                        PostalCode = "94111",
                        Country = "US"
                    }
                },
                Status = "active"
            };

            // If cardholder exists, try to update with new terms acceptance
            if (cardholder != null)
            {
                try
                {
                    var updateOptions = new CardholderUpdateOptions
                    {
                        Individual = new CardholderIndividualOptions
                        {
                            CardIssuing = new CardholderIndividualCardIssuingOptions
                            {
                                UserTermsAcceptance = new CardholderIndividualCardIssuingUserTermsAcceptanceOptions
                                {
                                    Date = DateTime.UtcNow,
                                    Ip = "192.168.1.1",
                                    UserAgent = "Mozilla/5.0"
                                }
                            }
                        }
                    };
                    return await cardholderService.UpdateAsync(cardholder.Id, updateOptions);
                }
                catch
                {
                    // If update fails, return existing cardholder
                    return cardholder;
                }
            }

            return await cardholderService.CreateAsync(createOptions);
        }

        public async Task<StripeCardModel> CreateCardAsync(string cardholderName, string email, string cardType)
        {
            var cardholder = await GetOrCreateCardholderAsync(cardholderName, email);
            var cardService = new Stripe.Issuing.CardService();

            var cardOptions = new Stripe.Issuing.CardCreateOptions
            {
                Cardholder = cardholder.Id,
                Currency = "usd",
                Type = "virtual",
                Status = "active"
            };

            var stripeCard = await cardService.CreateAsync(cardOptions);

            // Fetch the card again with expand to get the unmasked number and CVC
            var getOptions = new Stripe.Issuing.CardGetOptions
            {
                Expand = new List<string> { "number", "cvc" }
            };
            stripeCard = await cardService.GetAsync(stripeCard.Id, getOptions);

            return new StripeCardModel
            {
                StripeCardId = stripeCard.Id,
                Last4 = stripeCard.Last4,
                Brand = stripeCard.Brand,
                ExpiryMonth = (int)stripeCard.ExpMonth,
                ExpiryYear = (int)stripeCard.ExpYear,
                Status = stripeCard.Status,
                CardHolderName = cardholderName,
                CardNumber = stripeCard.Number ?? "",
                Cvv = stripeCard.Cvc ?? ""
            };
        }

        public async Task<string> FreezeCardAsync(string stripeCardId)
        {
            var cardService = new Stripe.Issuing.CardService();
            var updateOptions = new Stripe.Issuing.CardUpdateOptions
            {
                Status = "inactive"
            };
            var card = await cardService.UpdateAsync(stripeCardId, updateOptions);
            return card.Status;
        }

        public async Task<string> UnfreezeCardAsync(string stripeCardId)
        {
            var cardService = new Stripe.Issuing.CardService();
            var updateOptions = new Stripe.Issuing.CardUpdateOptions
            {
                Status = "active"
            };
            var card = await cardService.UpdateAsync(stripeCardId, updateOptions);
            return card.Status;
        }

        public async Task<string> CancelCardAsync(string stripeCardId)
        {
            var cardService = new Stripe.Issuing.CardService();
            var updateOptions = new Stripe.Issuing.CardUpdateOptions
            {
                Status = "canceled"
            };
            var card = await cardService.UpdateAsync(stripeCardId, updateOptions);
            return card.Status;
        }
    }
}
