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
    public class BillsController : ControllerBase
    {
        private readonly IBillsService _billsService;
        public BillsController(IBillsService billsService) => _billsService = billsService;
        private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpPost("pay")]
        public async Task<IActionResult> Pay(PayBillRequest request)
        {
            var result = await _billsService.PayBillAsync(CurrentUserId, request);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetHistory() => Ok(await _billsService.GetHistoryAsync(CurrentUserId));

        [HttpGet("providers")]
        public async Task<IActionResult> GetProviders() => Ok(await _billsService.GetProvidersAsync());
    }
}
