using System.Security.Claims;
using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BankE.API.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class CardsController : ControllerBase
    {
        private readonly ICardsService _cardsService;
        public CardsController(ICardsService cardsService) => _cardsService = cardsService;
        private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpGet]
        public async Task<IActionResult> Get() => Ok(await _cardsService.GetCardsAsync(CurrentUserId));

        [HttpPost("add")]
        public async Task<IActionResult> Add(AddCardRequest request)
        {
            var result = await _cardsService.AddCardAsync(CurrentUserId, request);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpPut("{id}/freeze")]
        public async Task<IActionResult> Freeze(int id)
        {
            var result = await _cardsService.ToggleFreezeAsync(CurrentUserId, id);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var result = await _cardsService.DeleteCardAsync(CurrentUserId, id);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }
    }
}
