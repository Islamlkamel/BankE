using BankE.Application.DTOs;
using BankE.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BankE.API.Controllers
{
    [Authorize(Roles = "Admin")]
    [ApiController]
    [Route("api/[controller]")]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _adminService;

        public AdminController(IAdminService adminService) => _adminService = adminService;

        [HttpGet("users")]
        public async Task<IActionResult> GetUsers([FromQuery] string? search, [FromQuery] bool? isActive)
        {
            var result = await _adminService.GetUsersAsync(search, isActive);
            return Ok(result);
        }

        [HttpPut("users/{id}/toggle-status")]
        public async Task<IActionResult> ToggleStatus(int id)
        {
            var result = await _adminService.ToggleUserStatusAsync(id);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpPost("adjust-balance")]
        public async Task<IActionResult> AdjustBalance(AdjustBalanceRequest request)
        {
            var result = await _adminService.AdjustBalanceAsync(request);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpGet("loans/pending")]
        public async Task<IActionResult> GetPendingLoans()
        {
            var result = await _adminService.GetPendingLoansAsync();
            return Ok(result);
        }

        [HttpGet("loans")]
        public async Task<IActionResult> GetAllLoans([FromQuery] string? status = null)
        {
            var result = await _adminService.GetAllLoansAsync(status);
            return Ok(result);
        }

        [HttpPost("loans/{id}/approve")]
        public async Task<IActionResult> ApproveLoan(int id, [FromBody] LoanReviewRequest request)
        {
            var result = await _adminService.ApproveLoanAsync(id, request.Note);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpPost("loans/{id}/reject")]
        public async Task<IActionResult> RejectLoan(int id, [FromBody] LoanReviewRequest request)
        {
            var result = await _adminService.RejectLoanAsync(id, request.Note);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpPost("loans/review")]
        public async Task<IActionResult> ReviewLoan(LoanReviewRequest request)
        {
            var result = await _adminService.ReviewLoanAsync(request);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpGet("dashboard-stats")]
        public async Task<IActionResult> GetStats()
        {
            var result = await _adminService.GetDashboardStatsAsync();
            return Ok(result);
        }

        [HttpGet("transactions")]
        public async Task<IActionResult> GetTransactions(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10,
            [FromQuery] string? search = null,
            [FromQuery] string? type = null,
            [FromQuery] string? status = null,
            [FromQuery] DateTime? startDate = null,
            [FromQuery] DateTime? endDate = null,
            [FromQuery] string? sortBy = "date",
            [FromQuery] bool sortDescending = true)
        {
            var result = await _adminService.GetTransactionsAsync(
                page, pageSize, search, type, status, startDate, endDate, sortBy, sortDescending);
            return Ok(result);
        }
    }
}
