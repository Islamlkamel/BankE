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
    public class AtmController : ControllerBase
    {
        private readonly IAtmService _atmService;
        public AtmController(IAtmService atmService) => _atmService = atmService;
        private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpPost("deposit")]
        public async Task<IActionResult> Deposit(AtmTransactionRequest request)
        {
            var result = await _atmService.DepositAsync(CurrentUserId, request);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpPost("withdraw")]
        public async Task<IActionResult> Withdraw(AtmTransactionRequest request)
        {
            var result = await _atmService.WithdrawAsync(CurrentUserId, request);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }
    }
}
