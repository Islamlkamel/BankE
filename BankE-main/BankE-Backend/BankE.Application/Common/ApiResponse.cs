namespace BankE.Application.Common
{
    public class ApiResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public List<string> Errors { get; set; } = new();

        public static ApiResponse Ok(string message = "") => new() { Success = true, Message = message };
        public static ApiResponse Fail(string message, List<string>? errors = null) => new() { Success = false, Message = message, Errors = errors ?? new() };
    }

    public class ApiResponse<T> : ApiResponse
    {
        public T? Data { get; set; }

        public static ApiResponse<T> Ok(T data, string message = "") => new() { Success = true, Data = data, Message = message };
        public new static ApiResponse<T> Fail(string message, List<string>? errors = null) => new() { Success = false, Message = message, Errors = errors ?? new() };
    }
}
