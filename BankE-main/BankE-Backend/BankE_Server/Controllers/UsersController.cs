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
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IWebHostEnvironment _environment;

        public UsersController(IUserService userService, IWebHostEnvironment environment)
        {
            _userService = userService;
            _environment = environment;
        }

        private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        private bool IsAdmin => User.IsInRole("Admin");

        [HttpGet("{userId}")]
        public async Task<IActionResult> GetUserProfile(int userId)
        {
            var result = await _userService.GetProfileAsync(userId, CurrentUserId, IsAdmin);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpPut("{userId}")]
        public async Task<IActionResult> UpdateUserProfile(int userId, [FromBody] UpdateUserRequest request)
        {
            var result = await _userService.UpdateProfileAsync(userId, CurrentUserId, IsAdmin, request);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }

        [HttpPost("register-fcm-token")]
        public async Task<IActionResult> RegisterFcmToken([FromBody] RegisterFcmRequest request)
        {
            var result = await _userService.RegisterFcmTokenAsync(CurrentUserId, request.Token);
            return Ok(result);
        }

        [HttpPost("upload-avatar")]
        public async Task<IActionResult> UploadAvatar(IFormFile file)
        {
            if (file == null || file.Length == 0) return BadRequest("No file uploaded");

            var uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads", "avatars");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

            var fileName = $"avatar_{CurrentUserId}_{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            var filePath = Path.Combine(uploadsFolder, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            var avatarUrl = $"/uploads/avatars/{fileName}";
            var result = await _userService.UpdateAvatarAsync(CurrentUserId, avatarUrl);
            return Ok(result);
        }

        [HttpDelete("{userId}")]
        public async Task<IActionResult> DeleteAccount(int userId)
        {
            var result = await _userService.DeleteAccountAsync(userId, CurrentUserId, IsAdmin);
            if (!result.Success) return BadRequest(result);
            return Ok(result);
        }
    }
}
