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
    public class BeneficiariesController : ControllerBase
    {
        private readonly IBeneficiaryService _beneficiaryService;
        public BeneficiariesController(IBeneficiaryService beneficiaryService) => _beneficiaryService = beneficiaryService;
        private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpGet]
        public async Task<IActionResult> Get() => Ok(await _beneficiaryService.GetBeneficiariesAsync(CurrentUserId));

        [HttpPost]
        public async Task<IActionResult> Add(BeneficiaryRequest request)
        {
            var result = await _beneficiaryService.AddBeneficiaryAsync(CurrentUserId, request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var result = await _beneficiaryService.DeleteBeneficiaryAsync(CurrentUserId, id);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }
    }
}
