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
    public class LoansController : ControllerBase
    {
        private readonly ILoansService _loansService;
        private readonly IWebHostEnvironment _environment;

        public LoansController(ILoansService loansService, IWebHostEnvironment environment)
        {
            _loansService = loansService;
            _environment = environment;
        }

        private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        [HttpGet]
        public async Task<IActionResult> Get() => Ok(await _loansService.GetUserLoansAsync(CurrentUserId));

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var loan = await _loansService.GetUserLoansAsync(CurrentUserId);
            var userLoan = loan.Data?.FirstOrDefault(l => l.Id == id);
            
            if (userLoan == null)
                return NotFound(new { message = "Loan not found" });

            var response = new
            {
                userLoan.Id,
                userLoan.UserId,
                userLoan.Amount,
                userLoan.Purpose,
                DurationMonths = userLoan.TermMonths,
                MonthlyPayment = userLoan.TermMonths > 0 ? userLoan.Amount / userLoan.TermMonths : 0,
                userLoan.Status,
                userLoan.AppliedAt,
                userLoan.PdfFileName,
                FileUrl = !string.IsNullOrEmpty(userLoan.PdfFileName) && FileExists(userLoan.PdfFileName) 
                    ? $"/api/loans/{id}/download" 
                    : null,
                FileExists = FileExists(userLoan.PdfFileName)
            };

            return Ok(response);
        }

        [HttpGet("{id}/download")]
        public async Task<IActionResult> DownloadFile(int id)
        {
            var loan = await _loansService.GetUserLoansAsync(CurrentUserId);
            var userLoan = loan.Data?.FirstOrDefault(l => l.Id == id);
            
            if (userLoan == null || string.IsNullOrEmpty(userLoan.PdfFileName))
                return NotFound(new { message = "Loan or document not found" });

            var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var filePath = Path.Combine(webRoot, userLoan.PdfFileName);
            
            if (!System.IO.File.Exists(filePath))
                return NotFound(new { message = "Document file not found" });

            var fileBytes = System.IO.File.ReadAllBytes(filePath);
            var fileName = Path.GetFileName(userLoan.PdfFileName);
            
            return File(fileBytes, "application/pdf", fileName);
        }

        private bool FileExists(string? filePath)
        {
            if (string.IsNullOrEmpty(filePath))
                return false;

            var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var fullPath = Path.Combine(webRoot, filePath);
            return System.IO.File.Exists(fullPath);
        }

        [HttpPost("apply")]
        public async Task<IActionResult> Apply([FromForm] ApplyLoanDto request)
        {
            string? filePath = null;
            if (request.Document != null)
            {
                var webRoot = _environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
                var uploadsFolder = Path.Combine(webRoot, "uploads", "loans");
                if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

                var fileName = Guid.NewGuid().ToString() + Path.GetExtension(request.Document.FileName);
                filePath = Path.Combine("uploads", "loans", fileName);
                var fullPath = Path.Combine(uploadsFolder, fileName);

                using (var stream = new FileStream(fullPath, FileMode.Create))
                {
                    await request.Document.CopyToAsync(stream);
                }
            }

            var result = await _loansService.ApplyAsync(CurrentUserId, new LoanRequest(request.Amount, request.TermMonths, request.Purpose), filePath);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }
    }

    public class ApplyLoanDto
    {
        public decimal Amount { get; set; }
        public int TermMonths { get; set; }
        public string Purpose { get; set; } = null!;
        public IFormFile? Document { get; set; }
    }
}
