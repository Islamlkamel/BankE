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
    public class TransferController : ControllerBase
    {
        private readonly ITransferService _transferService;

        public TransferController(ITransferService transferService) => _transferService = transferService;

        private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpPost]
        public async Task<IActionResult> Transfer(TransferRequest request)
        {
            var result = await _transferService.TransferAsync(CurrentUserId, request);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }
    }
}
