# BankE Technical Documentation: ATM Deposit, ATM Withdraw, Money Transfer

Generated from the current source code in this repository.

## Scope

This document covers only:

1. ATM Deposit
2. ATM Withdraw
3. Money Transfer

When behavior was not found in the source code, it is marked as **Not Found in Code** or **Not Implemented**.

## Source Files Reviewed

| Area | Files |
|---|---|
| Backend controllers | `BankE-Backend/BankE_Server/Controllers/AtmController.cs`, `BankE-Backend/BankE_Server/Controllers/TransferController.cs`, `BankE-Backend/BankE_Server/Controllers/AccountController.cs` |
| Backend services | `BankE-Backend/BankE.Application/Services/Services.cs`, `BankE-Backend/BankE.Application/Interfaces/IServices.cs` |
| Backend DTOs and responses | `BankE-Backend/BankE.Application/DTOs/AllDtos.cs`, `BankE-Backend/BankE.Application/Common/ApiResponse.cs` |
| Backend persistence | `BankE-Backend/BankE.Infrastructure/Persistence/BankEDbContext.cs`, `BankE-Backend/BankE.Infrastructure/Repositories/Repositories.cs`, `BankE-Backend/BankE.Infrastructure/Repositories/Repository.cs`, `BankE-Backend/BankE.Infrastructure/Repositories/UnitOfWork.cs` |
| Backend entities/schema | `BankE-Backend/BankE.Domain/Entities/Account.cs`, `BankE-Backend/BankE.Domain/Entities/Transaction.cs`, `BankE-Backend/BankE.Domain/Entities/User.cs`, `BankE-Backend/BankE.Infrastructure/Migrations/20260531220226_InitialPostgres.cs` |
| Backend auth/validation | `BankE-Backend/BankE_Server/Program.cs`, `BankE-Backend/BankE_Server/Filters/ValidationFilterAttribute.cs`, `BankE-Backend/BankE_Server/Middlewares/ExceptionMiddleware.cs`, `BankE-Backend/BankE.Infrastructure/Authentication/JwtProvider.cs` |
| Frontend API/data | `BankE-main/lib/core/api/api_client.dart`, `BankE-main/lib/core/api/other_services.dart`, `BankE-main/lib/data/datasources/remote_account_data_source.dart`, `BankE-main/lib/data/repositories/account_repository_impl.dart` |
| Frontend domain/bloc | `BankE-main/lib/domain/usecases/perform_transfer.dart`, `BankE-main/lib/domain/usecases/atm_transaction.dart`, `BankE-main/lib/domain/usecases/detect_fraud.dart`, `BankE-main/lib/Presentation/bloc/transfer_bloc.dart`, `BankE-main/lib/Presentation/bloc/transfer_event.dart`, `BankE-main/lib/Presentation/bloc/transfer_state.dart`, `BankE-main/lib/Presentation/bloc/otp/otp_bloc.dart` |
| Frontend screens | `BankE-main/lib/Presentation/Views/atm/atm_screen.dart`, `BankE-main/lib/Presentation/Views/transfer/transfer_screen.dart`, `BankE-main/lib/Presentation/Views/transfer/transfer_amount_screen.dart`, `BankE-main/lib/Presentation/Views/transfer/transfer_review_screen.dart`, `BankE-main/lib/Presentation/Views/transfer/transfer_otp_screen.dart`, `BankE-main/lib/Presentation/Views/transfer/transfer_success_screen.dart`, `BankE-main/lib/Presentation/Views/home_dashboard/home_dashboard.dart` |

## Shared Implementation Notes

| Item | Current implementation |
|---|---|
| Backend base route | Controllers use `[Route("api/[controller]")]`. |
| Frontend base URL | `ApiClient.baseUrl` defaults to `http://localhost:5221/api`. |
| Authentication | `AtmController`, `TransferController`, and `AccountController` are decorated with `[Authorize]`. |
| Current user identity | Backend reads `ClaimTypes.NameIdentifier` from JWT and parses it as the user ID. |
| Response envelope | Service success returns `ApiResponse<T>` with `success`, `message`, `errors`, and `data`. |
| Handled service failure | Controllers return HTTP `400 Bad Request` when `result.Success == false`. |
| Unhandled exceptions | `ExceptionMiddleware` returns HTTP `500` with `statusCode`, `message`, and `detailed`. |
| Validation filter | Global `ValidationFilterAttribute` returns HTTP `400` with `message: "Validation failed"` and field errors if `ModelState` is invalid. |
| Explicit DTO validation attributes | Not Found in Code for `TransferRequest` and `AtmTransactionRequest`. |
| Unit of work | Money-changing services call `BeginTransactionAsync`, `SaveChangesAsync`, then `CommitTransactionAsync`; failures roll back. |
| Notifications | Created after commit through `NotificationService`; notification failures are swallowed by `NotificationDispatch.TrySendAsync`. |
| Account ID from Flutter | Flutter passes hardcoded `AppConstants.currentAccountId = "acc_123"` into use cases, but backend deposit/withdraw/transfer use the JWT user ID, not the passed account ID. |

## API Response Shapes

### Standard Success Envelope

```json
{
  "success": true,
  "message": "",
  "errors": [],
  "data": {}
}
```

### Standard Service Error Envelope

```json
{
  "success": false,
  "message": "Error message",
  "errors": [],
  "data": null
}
```

### Model Validation Error Shape

```json
{
  "message": "Validation failed",
  "errors": {
    "fieldName": ["Validation message"]
  }
}
```

### Unhandled Exception Shape

```json
{
  "statusCode": 500,
  "message": "Internal Server Error. Please try again later.",
  "detailed": "Exception message"
}
```

---

# Feature 1: ATM Deposit

## Feature Overview

### Purpose

Allows an authenticated user to increase their account balance by submitting an ATM deposit amount. The backend records the deposit as a completed transaction and creates a notification after the database transaction is committed.

### User Flow

| Step | Current flow |
|---|---|
| 1 | User opens the dashboard. |
| 2 | User taps the `ATM` action button. |
| 3 | `AtmScreen` opens with available balance, a deposit/withdraw segmented control, amount input, optional note input, and submit button. |
| 4 | Deposit mode is selected by default. |
| 5 | User enters an amount and optionally a note. |
| 6 | Flutter validates that amount parses as a number and is greater than zero. |
| 7 | Flutter dispatches `AtmTransactionEvent` with `isDeposit = true`. |
| 8 | `TransferBloc` calls `AtmTransactionUseCase.deposit`. |
| 9 | Remote data source calls `POST /api/Atm/deposit`. |
| 10 | Backend validates amount and account existence, updates balance, inserts a transaction, commits, then creates a notification. |
| 11 | Flutter refreshes account balance and transactions. |
| 12 | Flutter navigates to `TransferSuccessScreen`. |

## Business Rules

| Rule | Current implementation |
|---|---|
| Authentication required | Yes. `[Authorize]` on `AtmController`. |
| User/account source | Backend uses JWT `NameIdentifier` to load the user's account. |
| Amount must be positive | Yes. Backend rejects `Amount <= 0`. Frontend also rejects null/invalid/non-positive input. |
| Deposit balance update | `account.Balance += request.Amount`. |
| Balance check before deposit | Not Implemented. Deposits do not require existing balance checks. |
| Deposit transaction record | A `Transactions` row is created with sender and receiver both set to the same account. |
| Transaction status | Hardcoded to `"Completed"`. |
| Transaction timestamp | `DateTime.UtcNow` in backend. |
| Description without note | `"ATM Deposit"`. |
| Description with note | `"ATM Deposit - {note}"`. |
| Notification | After commit, creates notification title `"ATM Deposit"` and message `"Deposited {amount:N2}."`. |
| Notification failure handling | Notification errors are swallowed and do not fail the deposit response. |
| Deposit limits | Not Found in Code. No daily, monthly, per-transaction, currency, or denomination limits. |
| ATM machine identification | Not Implemented. Request has no ATM ID/location/device field. |
| Cash acceptance/reconciliation | Not Implemented. |
| Account active status check | Not Found in `AtmService`. Existing JWTs are accepted by `[Authorize]`; service does not check `User.IsActive`. |
| OTP requirement | Not Implemented for ATM Deposit. |

## Validation Rules

| Validation | Frontend | Backend |
|---|---|---|
| Auth token required | `ApiClient` attaches Bearer token for non-public paths if stored. | `[Authorize]` requires a valid JWT. |
| Request body required | Not explicitly validated in `AtmScreen`; the API call always sends an object. | No explicit code in service. ASP.NET model binding/global validation can return `400` for invalid model state. |
| Amount required | Empty/invalid amount fails `double.tryParse` and shows `Enter a valid amount`. | `Amount` is a non-nullable decimal on `AtmTransactionRequest`; explicit service rule rejects `Amount <= 0`. |
| Amount > 0 | Yes. | Yes: `"Amount must be greater than zero"`. |
| Note required | No. Optional. Empty string is sent as absent/null by frontend. | No. `string.IsNullOrWhiteSpace(request.Note)` uses default description. |
| Note max length | Not Found in frontend. | No explicit service validation. DB column `Transactions.Description` has max length 200. Overlong note can fail during `SaveChangesAsync` and return `"Error during deposit: ..."` from catch block. |
| Account existence | Not checked in frontend. | Must find account by authenticated user ID; otherwise `"Account not found"`. |
| Balance check | Not applicable. | Not applicable. |
| User active/account status | Not Found in frontend for deposit. | Not Found in `AtmService`. |
| OTP | Not Implemented. | Not Implemented. |

## API Documentation

### POST `/api/Atm/deposit`

| Item | Details |
|---|---|
| HTTP method | `POST` |
| Auth | Required Bearer JWT |
| Frontend wrapper | `AtmService.deposit(amount, note)` posts to `/Atm/deposit` relative to `http://localhost:5221/api`. |
| Controller | `AtmController.Deposit` |
| Service | `AtmService.DepositAsync` |

#### Request Body

```json
{
  "amount": 250.00,
  "note": "Cash deposit"
}
```

| Field | Type | Required in code | Notes |
|---|---|---|---|
| `amount` | decimal | Service requires value greater than zero. | Missing/invalid amount handling can occur through model binding; no explicit `[Required]` attribute found. |
| `note` | string or null | No | Optional. Whitespace uses default `"ATM Deposit"` description. |

#### Success Response

Status code: `200 OK`

```json
{
  "success": true,
  "message": "",
  "errors": [],
  "data": {
    "newBalance": 1700.75,
    "message": "Deposit successful"
  }
}
```

#### Error Responses

| Scenario | Status | Body/message |
|---|---:|---|
| Missing/invalid JWT | `401` | Default ASP.NET unauthorized response. Custom body Not Found in Code. |
| Amount is zero or negative | `400` | `success: false`, `message: "Amount must be greater than zero"` |
| Authenticated user has no account | `400` | `success: false`, `message: "Account not found"` |
| DB/save failure during deposit | `400` | `success: false`, `message: "Error during deposit: {exception message}"` |
| Model state invalid | `400` | `message: "Validation failed"`, `errors: {...}` |
| Unhandled exception | `500` | `statusCode: 500`, `message: "Internal Server Error. Please try again later."`, `detailed: ...` |

## Frontend Flow

| Screen/component | Behavior |
|---|---|
| `HomeDashboard` | Shows balance and action buttons. `ATM` navigates to `AtmScreen`. |
| `AtmScreen` | Shows available balance from `AccountBloc` if loaded. Deposit is default selected mode. |
| Amount field | Uses `TextInputType.numberWithOptions(decimal: true)`. No input formatter limits decimals on ATM screen. |
| Note field | Optional free text. |
| Submit | Parses amount with `double.tryParse(_amountController.text.trim())`; if null or `<= 0`, shows snackbar `Enter a valid amount`. |
| Loading | Submit button disabled when `TransferBloc` is `TransferLoading`; button shows spinner. |
| Success | `TransferBloc` emits `TransferSuccess`; `AtmScreen` navigates to `TransferSuccessScreen`. |
| Error | `TransferBloc` emits `TransferError`; snackbar shows error message with red background. |
| Post-success refresh | `TransferBloc` dispatches `FetchTransactions(AppConstants.currentAccountId)` and `FetchAccountBalance(AppConstants.currentAccountId)`. Backend ignores this hardcoded account ID for the actual API calls. |

## Backend Flow

| Step | Operation |
|---|---|
| 1 | `AtmController.Deposit` reads current user ID from JWT claim. |
| 2 | Calls `AtmService.DepositAsync(userId, request)`. |
| 3 | Service rejects `request.Amount <= 0`. |
| 4 | Service loads account with `_unitOfWork.Accounts.GetByUserIdAsync(userId)`. |
| 5 | Service rejects missing account. |
| 6 | Begins EF transaction using `_unitOfWork.BeginTransactionAsync()`. |
| 7 | Adds amount to account balance. |
| 8 | Adds `Transaction` entity with same sender/receiver account ID, amount, deposit description, status `"Completed"`, and UTC timestamp. |
| 9 | Calls `SaveChangesAsync()`. |
| 10 | Commits transaction. |
| 11 | On exception inside transaction block, rolls back and returns failure. |
| 12 | After commit, tries to send notification. |
| 13 | Returns new balance and message `"Deposit successful"`. |

## Database Impact

| Table | Operation |
|---|---|
| `Accounts` | Read one account by `UserId`. Update `Balance`. |
| `Transactions` | Insert one transaction row. |
| `Notifications` | Insert one notification row after successful commit. Notification insert is separate from the deposit transaction. |
| `Users` | Not read by `AtmService`. Used indirectly only by authentication/JWT. |

### Before/After Balance

| Account | Before | Operation | After |
|---|---:|---:|---:|
| Current user's account | `B` | `+ amount` | `B + amount` |

### Transaction Row

| Column | Value |
|---|---|
| `SenderAccountId` | Current account ID |
| `ReceiverAccountId` | Current account ID |
| `Amount` | Request amount |
| `Description` | `"ATM Deposit"` or `"ATM Deposit - {note}"` |
| `Status` | `"Completed"` |
| `CreatedAt` | `DateTime.UtcNow` |

## Test Cases

| ID | Type | Scenario | Steps | Expected result |
|---|---|---|---|---|
| ATM-D-001 | Positive | Deposit valid amount without note | Auth user with account; call `POST /api/Atm/deposit` with `amount: 100`. | `200 OK`; new balance increases by 100; transaction created with description `"ATM Deposit"`; notification created. |
| ATM-D-002 | Positive | Deposit valid amount with note | Submit `amount: 100`, `note: "Salary cash"`. | Transaction description is `"ATM Deposit - Salary cash"`. |
| ATM-D-003 | Positive | Frontend success flow | Open ATM, keep Deposit mode, enter valid amount, submit. | Loading indicator appears; success screen opens; balance and transactions are refreshed. |
| ATM-D-004 | Validation | Zero amount | Submit `amount: 0`. | Frontend blocks with `Enter a valid amount`; direct API returns `400` with `"Amount must be greater than zero"`. |
| ATM-D-005 | Validation | Negative amount | Submit `amount: -1`. | Direct API returns `400` with `"Amount must be greater than zero"`; frontend blocks if typed negative parse is allowed by keyboard. |
| ATM-D-006 | Validation | Non-numeric frontend amount | Enter non-numeric value if platform keyboard allows it. | Frontend shows `Enter a valid amount`; API not called. |
| ATM-D-007 | Security | Missing token | Call endpoint without `Authorization` header. | `401 Unauthorized`. |
| ATM-D-008 | Security | Invalid/expired token | Call endpoint with invalid JWT. | `401 Unauthorized`. |
| ATM-D-009 | Negative | User has no account | Auth token for user without account; call deposit. | `400` with `"Account not found"`. |
| ATM-D-010 | Edge | Decimal amount | Deposit `10.25`. | Balance increases by `10.25`; DB stores numeric value in `Accounts.Balance` and `Transactions.Amount`. |
| ATM-D-011 | Edge | Very long note | Submit note causing description length over 200 chars. | No frontend validation; backend may fail during DB save and return `400` with `"Error during deposit: ..."`. |
| ATM-D-012 | Security/status | Deactivated user with still-valid JWT | Use existing valid token after admin deactivation. | Service active-status check is Not Found in Code; expected result must be verified in runtime auth behavior. |

## Known Issues

| Issue | Impact |
|---|---|
| No ATM deposit OTP | Deposit can be submitted after login without transaction OTP. |
| No ATM ID/location/device fields | Cannot audit physical ATM source. |
| No cash reconciliation state | Deposit is treated as immediately completed. |
| No explicit deposit limit | QA cannot verify daily/monthly/per-ATM limits because none are implemented. |
| No note length validation before DB | Overlong descriptions can fail at save time instead of returning a clean validation message. |
| Success screen text says transfer | ATM deposit uses `TransferSuccessScreen`, which displays `"Transfer Successful!"` and `"Your money has been sent successfully."`. |
| Static receipt reference | `TransferSuccessScreen` default reference number is hardcoded as `TXN778234910`; backend transaction ID is not displayed. |
| Active user status not checked inside `AtmService` | If an already-issued token remains valid after deactivation, ATM service does not re-check `User.IsActive`. |

## Current Project Status

| Category | Status |
|---|---|
| Completed | Authenticated deposit endpoint; positive amount validation; account lookup; balance increment; transaction row creation; DB transaction/rollback; notification after commit; Flutter ATM deposit UI; balance/transaction refresh after success. |
| Partially completed | Frontend receipt/success handling is reused from transfer and is not deposit-specific. |
| Missing | ATM OTP; ATM device/location; deposit limits; cash reconciliation; active-account check in service; explicit DTO validation attributes; clean note max-length validation. |
| Recommended improvements | Add server-side request validation attributes; add feature-specific success screen; include transaction ID in API response; add audit fields; check `User.IsActive` in money services; add integration tests for transaction rollback. |

---

# Feature 2: ATM Withdraw

## Feature Overview

### Purpose

Allows an authenticated user to decrease their account balance by submitting an ATM withdrawal amount. The backend records the withdrawal as a completed transaction and creates a notification after commit.

### User Flow

| Step | Current flow |
|---|---|
| 1 | User opens dashboard and taps `ATM`. |
| 2 | `AtmScreen` opens. |
| 3 | User selects `Withdraw` in the segmented control. |
| 4 | User enters an amount and optional note. |
| 5 | Flutter validates amount parses as a number and is greater than zero. |
| 6 | Flutter dispatches `AtmTransactionEvent` with `isDeposit = false`. |
| 7 | `TransferBloc` calls `AtmTransactionUseCase.withdraw`. |
| 8 | Remote data source calls `POST /api/Atm/withdraw`. |
| 9 | Backend validates amount, account existence, and sufficient balance. |
| 10 | Backend subtracts the amount, inserts a transaction, commits, then creates notification. |
| 11 | Flutter refreshes account balance and transactions. |
| 12 | Flutter navigates to `TransferSuccessScreen`. |

## Business Rules

| Rule | Current implementation |
|---|---|
| Authentication required | Yes. `[Authorize]` on `AtmController`. |
| User/account source | Backend uses JWT `NameIdentifier` to load the user's account. |
| Amount must be positive | Yes. Backend rejects `Amount <= 0`; frontend also checks. |
| Sufficient balance required | Yes. Backend rejects if `account.Balance < request.Amount`. |
| Exact-balance withdrawal | Allowed because check is `<`, not `<=`. |
| Withdrawal balance update | `account.Balance -= request.Amount`. |
| Transaction record | A `Transactions` row is created with sender and receiver both set to the same account. |
| Transaction status | Hardcoded to `"Completed"`. |
| Transaction timestamp | `DateTime.UtcNow`. |
| Description without note | `"ATM Withdrawal"`. |
| Description with note | `"ATM Withdrawal - {note}"`. |
| Notification | After commit, creates notification title `"ATM Withdrawal"` and message `"Withdrew {amount:N2}."`. |
| Withdrawal limits | Not Found in Code. No daily, monthly, per-transaction, currency, or denomination limits. |
| ATM cash availability | Not Implemented. |
| Account active status check | Not Found in `AtmService`. |
| OTP requirement | Not Implemented for ATM Withdraw. |

## Validation Rules

| Validation | Frontend | Backend |
|---|---|---|
| Auth token required | `ApiClient` attaches Bearer token for non-public paths if stored. | `[Authorize]` requires valid JWT. |
| Amount required | Empty/invalid amount shows `Enter a valid amount`. | `Amount` is non-nullable decimal; service rejects `Amount <= 0`. |
| Amount > 0 | Yes. | Yes: `"Amount must be greater than zero"`. |
| Sufficient balance | Not checked by `AtmScreen`; current balance is displayed only. | Yes: `"Insufficient balance"`. |
| Note required | No. | No. |
| Note max length | Not Found. | No explicit service validation; DB `Description` max length is 200. |
| Account existence | Not checked in frontend. | Must find account by authenticated user ID; otherwise `"Account not found"`. |
| User active/account status | Not Found. | Not Found in `AtmService`. |
| OTP | Not Implemented. | Not Implemented. |

## API Documentation

### POST `/api/Atm/withdraw`

| Item | Details |
|---|---|
| HTTP method | `POST` |
| Auth | Required Bearer JWT |
| Frontend wrapper | `AtmService.withdraw(amount, note)` posts to `/Atm/withdraw` relative to `http://localhost:5221/api`. |
| Controller | `AtmController.Withdraw` |
| Service | `AtmService.WithdrawAsync` |

#### Request Body

```json
{
  "amount": 50.00,
  "note": "ATM cash"
}
```

| Field | Type | Required in code | Notes |
|---|---|---|---|
| `amount` | decimal | Service requires value greater than zero. | Also must be less than or equal to current balance. |
| `note` | string or null | No | Optional. Whitespace uses default `"ATM Withdrawal"` description. |

#### Success Response

Status code: `200 OK`

```json
{
  "success": true,
  "message": "",
  "errors": [],
  "data": {
    "newBalance": 1400.75,
    "message": "Withdrawal successful"
  }
}
```

#### Error Responses

| Scenario | Status | Body/message |
|---|---:|---|
| Missing/invalid JWT | `401` | Default ASP.NET unauthorized response. Custom body Not Found in Code. |
| Amount is zero or negative | `400` | `success: false`, `message: "Amount must be greater than zero"` |
| Authenticated user has no account | `400` | `success: false`, `message: "Account not found"` |
| Insufficient balance | `400` | `success: false`, `message: "Insufficient balance"` |
| DB/save failure during withdrawal | `400` | `success: false`, `message: "Error during withdrawal: {exception message}"` |
| Model state invalid | `400` | `message: "Validation failed"`, `errors: {...}` |
| Unhandled exception | `500` | `statusCode: 500`, `message: "Internal Server Error. Please try again later."`, `detailed: ...` |

## Frontend Flow

| Screen/component | Behavior |
|---|---|
| `HomeDashboard` | `ATM` action navigates to `AtmScreen`. |
| `AtmScreen` | User selects `Withdraw`. Available balance is displayed but not used for client-side withdrawal blocking. |
| Amount field | Parses amount; rejects null and `<= 0`. |
| Note field | Optional. |
| Submit | Dispatches `AtmTransactionEvent` with `isDeposit = false`. |
| Loading | Button disabled during `TransferLoading`. |
| Success | Navigates to `TransferSuccessScreen`. |
| Error | Shows red snackbar with backend/frontend error message. |
| Post-success refresh | Dispatches transaction and balance refresh events. |

## Backend Flow

| Step | Operation |
|---|---|
| 1 | `AtmController.Withdraw` reads current user ID from JWT claim. |
| 2 | Calls `AtmService.WithdrawAsync(userId, request)`. |
| 3 | Rejects `request.Amount <= 0`. |
| 4 | Loads account by authenticated user ID. |
| 5 | Rejects missing account. |
| 6 | Rejects insufficient balance when `account.Balance < request.Amount`. |
| 7 | Begins EF transaction. |
| 8 | Subtracts amount from account balance. |
| 9 | Adds `Transaction` entity with same sender/receiver account ID, withdrawal description, status `"Completed"`, and UTC timestamp. |
| 10 | Saves and commits. |
| 11 | Rolls back and returns failure if any exception occurs inside transaction block. |
| 12 | Sends notification after commit. |
| 13 | Returns new balance and message `"Withdrawal successful"`. |

## Database Impact

| Table | Operation |
|---|---|
| `Accounts` | Read one account by `UserId`. Update `Balance`. |
| `Transactions` | Insert one transaction row. |
| `Notifications` | Insert one notification row after successful commit. |
| `Users` | Not read by `AtmService`. Used indirectly only by authentication/JWT. |

### Before/After Balance

| Account | Before | Operation | After |
|---|---:|---:|---:|
| Current user's account | `B` | `- amount` | `B - amount` |

### Transaction Row

| Column | Value |
|---|---|
| `SenderAccountId` | Current account ID |
| `ReceiverAccountId` | Current account ID |
| `Amount` | Request amount |
| `Description` | `"ATM Withdrawal"` or `"ATM Withdrawal - {note}"` |
| `Status` | `"Completed"` |
| `CreatedAt` | `DateTime.UtcNow` |

## Test Cases

| ID | Type | Scenario | Steps | Expected result |
|---|---|---|---|---|
| ATM-W-001 | Positive | Withdraw valid amount without note | Auth user has balance `B >= 100`; call withdraw with `amount: 100`. | `200 OK`; new balance is `B - 100`; transaction created with `"ATM Withdrawal"`; notification created. |
| ATM-W-002 | Positive | Withdraw valid amount with note | Submit `amount: 100`, `note: "Cash"`. | Transaction description is `"ATM Withdrawal - Cash"`. |
| ATM-W-003 | Positive/edge | Withdraw exact full balance | Balance is `100`; withdraw `100`. | `200 OK`; balance becomes `0`; transaction created. |
| ATM-W-004 | Validation | Zero amount | Submit `0`. | Frontend blocks; direct API returns `400` with `"Amount must be greater than zero"`. |
| ATM-W-005 | Validation | Negative amount | Submit `-10`. | Direct API returns `400` with `"Amount must be greater than zero"`. |
| ATM-W-006 | Negative | Insufficient balance | Balance is `50`; withdraw `100`. | `400` with `"Insufficient balance"`; no balance change; no transaction row. |
| ATM-W-007 | Negative | User has no account | Auth token for user without account. | `400` with `"Account not found"`. |
| ATM-W-008 | Security | Missing token | Call endpoint without token. | `401 Unauthorized`. |
| ATM-W-009 | Security | Invalid token | Call endpoint with invalid JWT. | `401 Unauthorized`. |
| ATM-W-010 | Edge | Decimal amount | Withdraw `10.25`. | Balance decreases by `10.25`; transaction amount is `10.25`. |
| ATM-W-011 | Edge | Very long note | Submit note causing description over 200 chars. | No frontend validation; backend may return `400` with `"Error during withdrawal: ..."`. |
| ATM-W-012 | UI | Insufficient balance from ATM screen | Enter amount greater than displayed balance and submit. | Frontend still calls API; backend returns error; snackbar displays error. |
| ATM-W-013 | Security/status | Deactivated user with still-valid JWT | Use existing valid token after admin deactivation. | Active-status check is Not Found in `AtmService`; runtime behavior should be verified. |

## Known Issues

| Issue | Impact |
|---|---|
| No ATM withdraw OTP | Withdrawal can be submitted after login without transaction OTP. |
| No client-side balance check on ATM withdrawal | User can submit an amount greater than displayed balance; backend catches it. |
| No ATM cash/denomination limits | QA cannot validate cash availability or supported denominations. |
| No explicit withdrawal limits | No daily/monthly/per-transaction limits are implemented. |
| No ATM ID/location/device fields | Withdrawal source cannot be audited as a physical ATM event. |
| Success screen text says transfer | ATM withdrawal uses transfer copy and receipt labels. |
| Static receipt reference | Success screen uses hardcoded `TXN778234910`. |
| Active user status not checked inside `AtmService` | Same risk as deposit. |

## Current Project Status

| Category | Status |
|---|---|
| Completed | Authenticated withdrawal endpoint; positive amount validation; account lookup; sufficient balance check; balance decrement; transaction row creation; DB transaction/rollback; notification after commit; Flutter ATM withdraw UI; refresh after success. |
| Partially completed | Frontend displays available balance but does not client-validate sufficient funds; success screen is not ATM-specific. |
| Missing | OTP; ATM device/location; cash/denomination validation; withdrawal limits; active-account check in service; explicit DTO validation attributes; note length validation. |
| Recommended improvements | Add client-side balance check; add server-side limits and audit fields; add feature-specific success receipt; return transaction ID; add tests for insufficient balance rollback. |

---

# Feature 3: Money Transfer

## Feature Overview

### Purpose

Allows an authenticated user to send money from their own account to another account, identified either by account number or by phone number. The backend debits the sender, credits the receiver, records one completed transaction, and creates notifications for both users.

### User Flow

| Step | Current flow |
|---|---|
| 1 | User opens dashboard. |
| 2 | User taps `Transfer`. |
| 3 | `TransferScreen` opens with balance header and recipient input. |
| 4 | User enters an 8-digit account number or an 11-digit phone number starting with `01`. |
| 5 | Flutter validates recipient format. |
| 6 | User continues to `TransferAmountScreen`. |
| 7 | User enters amount and optional notes. |
| 8 | Flutter validates amount is positive and, if account state is loaded, amount does not exceed displayed balance. |
| 9 | User continues to `TransferReviewScreen`. |
| 10 | Review screen shows transfer details and a confirmation button. |
| 11 | User taps confirm and goes to `TransferOtpScreen`. |
| 12 | OTP screen simulates sending OTP to `"User Device"`. |
| 13 | User enters OTP. Flutter requires exactly 6 characters. |
| 14 | `ApiOtpRepositoryImpl` accepts only code `"123456"` for transaction destination `"User Device"`. |
| 15 | After frontend OTP success, `TransferBloc` runs frontend fraud checks. |
| 16 | If fraud checks pass, Flutter calls `POST /api/Transfer`. |
| 17 | Backend validates amount, sender account, receiver account, same-account transfer, and balance. |
| 18 | Backend debits sender, credits receiver, inserts transaction, commits, then sends notifications. |
| 19 | Flutter refreshes balance and transactions. |
| 20 | Flutter navigates to `TransferSuccessScreen`. |

## Business Rules

| Rule | Current implementation |
|---|---|
| Authentication required | Yes. `[Authorize]` on `TransferController`. |
| Sender source | Backend uses JWT `NameIdentifier` to load sender account. |
| Receiver by account number | Backend first calls `Accounts.GetByAccountNumberAsync(request.ReceiverAccountNumber)`. |
| Receiver by phone number | If account number lookup fails, backend calls `Users.GetByPhoneAsync(request.ReceiverAccountNumber)` and then loads that user's account. |
| Amount must be positive | Yes. Backend rejects `Amount <= 0`; frontend also checks. |
| Sender account required | Yes. `"Sender account not found"`. |
| Receiver account required | Yes. `"Receiver account not found"`. |
| Same-account transfer blocked | Yes. Backend compares `senderAccount.Id == receiverAccount.Id`. |
| Sufficient balance required | Yes. Backend rejects if sender balance is less than amount. |
| Exact-balance transfer | Allowed because check is `<`, not `<=`. |
| Sender balance update | `senderAccount.Balance -= request.Amount`. |
| Receiver balance update | `receiverAccount.Balance += request.Amount`. |
| Transaction record | One `Transactions` row is created with sender account ID, receiver account ID, amount, request description, status `"Completed"`, and UTC timestamp. |
| Transaction status | Hardcoded to `"Completed"`. |
| Fees | Not Implemented. Review screen displays `"Zero Fee"`; backend performs no fee calculation. |
| Backend OTP | Not Implemented. OTP is frontend-only for transaction destination `"User Device"`. |
| Frontend fraud checks | Implemented before API call: amount `>= 10000`, rapid debit transactions, and mock geofence check. |
| Backend fraud checks | Not Implemented. |
| Transfer limits | Backend: Not Found in Code except balance. Frontend blocks amount `>= 10000` as fraud. |
| Receiver active status | Not Found in `TransferService`. |
| Sender active status after token issue | Not Found in `TransferService`. Login checks `User.IsActive`, but transfer service does not re-check. |
| Notifications | Sender gets `"Transfer Successful"`; receiver gets `"Money Received"` after DB commit. |
| Notification failure handling | Notification errors are swallowed and do not fail the transfer response. |

## Validation Rules

| Validation | Frontend | Backend |
|---|---|---|
| Auth token required | `ApiClient` attaches Bearer token for non-public paths if stored. | `[Authorize]` requires valid JWT. |
| Recipient required | Empty recipient shows `Please enter a recipient account`. | No explicit null/empty check. Missing or unmatched receiver eventually returns `"Receiver account not found"` or model validation may fail if invalid model state. |
| Recipient format | Must be either `^\d{8}$` or `^01\d{9}$`. Input formatter permits digits only. | No format validation. Backend accepts any string and searches account number, then phone. |
| Amount required | Empty/invalid amount becomes `0.0` and is rejected by frontend. | `Amount` is non-nullable decimal; service rejects `Amount <= 0`. |
| Amount decimals | `TransferAmountScreen` input formatter allows up to 2 decimal places. | No explicit decimal-place validation in service; DB column uses `numeric(18,2)`. |
| Amount > 0 | Yes. | Yes: `"Amount must be greater than zero"`. |
| Client sufficient balance | If `AccountBloc` state is `AccountLoaded`, frontend blocks `amount > state.account.balance`. If account state is not loaded, this client check is skipped. | Yes: `"Insufficient balance"`. |
| Sender account exists | Not checked in frontend. | Yes: `"Sender account not found"`. |
| Receiver account exists | Not checked before API beyond format. | Yes: account lookup by account number or phone; otherwise `"Receiver account not found"`. |
| Same account | Not checked in frontend. | Yes: `"Cannot transfer to the same account"`. |
| OTP length | OTP screen requires `text.length == 6`. | Not Implemented for transfer endpoint. |
| OTP value | For `"User Device"`, `ApiOtpRepositoryImpl` accepts only `"123456"`. | Not Implemented for transfer endpoint. |
| OTP delivery | `sendOtp` waits 300ms; no transfer OTP API call, email, or SMS. | Not Implemented. |
| Fraud amount check | `DetectFraudUseCase` throws if amount `>= 10000`. | Not Implemented. |
| Fraud rapid transactions | `DetectFraudUseCase` loads transactions and throws if at least 3 debit transactions occurred in last 5 minutes. | Not Implemented. |
| Fraud geofence | Mock location must be within 50 km of trusted zone. Default mock location is New York and trusted zones are New York and Los Angeles. | Not Implemented. |
| Notes required | No. | `TransferRequest.Description` is non-nullable in DTO but no explicit service validation. Frontend omits `description` if null/empty in API wrapper. |
| Description max length | Not Found in frontend. | No explicit service validation; DB `Transactions.Description` max length is 200. |
| User/account status | Not Found for transfer-specific frontend check. | Not Found in `TransferService` for sender or receiver active status. |

## API Documentation

### POST `/api/Transfer`

| Item | Details |
|---|---|
| HTTP method | `POST` |
| Auth | Required Bearer JWT |
| Frontend wrapper | `TransferService.transfer(receiverAccountNumber, amount, description)` posts to `/Transfer` relative to `http://localhost:5221/api`. |
| Controller | `TransferController.Transfer` |
| Service | `TransferService.TransferAsync` |

#### Request Body

```json
{
  "receiverAccountNumber": "12345678",
  "amount": 100.00,
  "description": "Dinner split"
}
```

| Field | Type | Required in code | Notes |
|---|---|---|---|
| `receiverAccountNumber` | string | Required by business logic to find receiver. | Backend also treats this value as phone number if account number lookup fails. |
| `amount` | decimal | Service requires value greater than zero. | Must be less than or equal to sender balance. |
| `description` | string | No explicit service validation. | Frontend sends this field only if non-null and non-empty. Backend saves request value directly. |

#### Success Response

Status code: `200 OK`

```json
{
  "success": true,
  "message": "",
  "errors": [],
  "data": {
    "newBalance": 900.75,
    "message": "Transfer successful"
  }
}
```

#### Error Responses

| Scenario | Status | Body/message |
|---|---:|---|
| Missing/invalid JWT | `401` | Default ASP.NET unauthorized response. Custom body Not Found in Code. |
| Amount is zero or negative | `400` | `success: false`, `message: "Amount must be greater than zero"` |
| Sender account missing | `400` | `success: false`, `message: "Sender account not found"` |
| Receiver account/phone not found | `400` | `success: false`, `message: "Receiver account not found"` |
| Same sender and receiver account | `400` | `success: false`, `message: "Cannot transfer to the same account"` |
| Insufficient sender balance | `400` | `success: false`, `message: "Insufficient balance"` |
| DB/save failure during transfer | `400` | `success: false`, `message: "Error during transfer: {exception message}"` |
| Model state invalid | `400` | `message: "Validation failed"`, `errors: {...}` |
| Unhandled exception | `500` | `statusCode: 500`, `message: "Internal Server Error. Please try again later."`, `detailed: ...` |

### Supporting Endpoint: GET `/api/Account/info`

Used by frontend account balance views and post-operation refresh.

| Item | Details |
|---|---|
| HTTP method | `GET` |
| Auth | Required Bearer JWT |
| Success | `200 OK` with `data.accountNumber`, `data.balance`, `data.ownerName`, `data.createdAt`. |
| Error | `400` with `"Account not found"` if no account exists. |

Example success:

```json
{
  "success": true,
  "message": "",
  "errors": [],
  "data": {
    "accountNumber": "12345678",
    "balance": 900.75,
    "ownerName": "User Name",
    "createdAt": "2026-06-18T10:00:00Z"
  }
}
```

### Supporting Endpoint: GET `/api/Account/transactions`

Used by frontend transaction lists, recent recipient extraction, fraud checks, and post-operation refresh.

| Item | Details |
|---|---|
| HTTP method | `GET` |
| Auth | Required Bearer JWT |
| Success | `200 OK` with an array of transaction response objects. |
| Error | `400` with `"Account not found"` if no account exists. |

Example transaction item:

```json
{
  "id": 1,
  "senderName": "Sender Name",
  "receiverName": "Receiver Name",
  "amount": 100.00,
  "description": "Dinner split",
  "status": "Completed",
  "type": "Debit",
  "createdAt": "2026-06-18T10:00:00Z"
}
```

Important frontend mismatch: `TransactionModel.fromJson` reads `json['direction']` and defaults to `"Debit"` when missing, while backend returns `type` as `"Debit"` or `"Credit"`. This can cause credits to display as debits in Flutter.

## Frontend Flow

| Screen/component | Behavior |
|---|---|
| `HomeDashboard` | `Transfer` action opens `TransferScreen`. |
| `TransferScreen` | User enters recipient account/phone. Empty input and invalid format are blocked with snackbars. |
| Recipient format | Account number must be 8 digits. Phone must be 11 digits starting with `01`. |
| Recent recipients | Extracted from loaded transactions whose description starts with `"Transfer to "`. Backend transfer description is user-provided, so this may not populate with real backend data. |
| `TransferAmountScreen` | User enters amount and notes. Amount input formatter allows up to two decimal places. |
| Client balance check | If account state is loaded, amount greater than displayed balance is blocked. |
| `TransferReviewScreen` | Shows amount, recipient, hardcoded bank name `"Contro Bank"`, transfer type `"Instant Transfer"`, and description. Shows `"Zero Fee"`. |
| `TransferOtpScreen` | Sends simulated OTP to `"User Device"` on entry; requires 6-character OTP; accepts only `"123456"`. |
| Transfer execution | After OTP verified, dispatches `InitiateTransfer`. |
| Fraud checks | `TransferBloc` runs `DetectFraudUseCase` before API call. |
| API call | `RemoteAccountDataSourceImpl.performTransfer` calls `TransferService.transfer`, then `apiClient.ensureSuccess`. |
| Loading | Verify button disabled when OTP or transfer is loading. |
| Success | `TransferSuccessScreen` shows amount, recipient, hardcoded transaction ID, current client date/time, and completed status. |
| Error | OTP errors and transfer errors show red snackbars. |
| Refresh | On transfer success, bloc dispatches transaction and balance refresh events. |

## Backend Flow

| Step | Operation |
|---|---|
| 1 | `TransferController.Transfer` reads current user ID from JWT claim. |
| 2 | Calls `TransferService.TransferAsync(senderUserId, request)`. |
| 3 | Rejects `request.Amount <= 0`. |
| 4 | Loads sender account by authenticated user ID. |
| 5 | Rejects missing sender account. |
| 6 | Tries to load receiver account by `request.ReceiverAccountNumber`. |
| 7 | If no receiver account found, tries to load a user by phone number equal to `request.ReceiverAccountNumber`. |
| 8 | If user by phone is found, loads that user's account. |
| 9 | Rejects missing receiver account. |
| 10 | Rejects same sender/receiver account ID. |
| 11 | Rejects insufficient sender balance. |
| 12 | Begins EF transaction. |
| 13 | Subtracts amount from sender balance. |
| 14 | Adds amount to receiver balance. |
| 15 | Adds `Transaction` entity with sender, receiver, amount, request description, status `"Completed"`, and UTC timestamp. |
| 16 | Saves and commits. |
| 17 | Rolls back and returns failure on exception inside transaction block. |
| 18 | Sends sender notification and receiver notification after commit. |
| 19 | Returns sender new balance and message `"Transfer successful"`. |

## Database Impact

| Table | Operation |
|---|---|
| `Accounts` | Read sender by `UserId`; read receiver by `AccountNumber`; optionally read receiver by `UserId` after phone lookup. Update sender and receiver balances. |
| `Users` | Optionally read receiver user by `PhoneNumber` if account-number lookup fails. |
| `Transactions` | Insert one transaction row. |
| `Notifications` | Insert sender and receiver notification rows after successful commit. Notification inserts are separate from the transfer transaction. |

### Before/After Balance

| Account | Before | Operation | After |
|---|---:|---:|---:|
| Sender | `S` | `- amount` | `S - amount` |
| Receiver | `R` | `+ amount` | `R + amount` |

### Transaction Row

| Column | Value |
|---|---|
| `SenderAccountId` | Sender account ID |
| `ReceiverAccountId` | Receiver account ID |
| `Amount` | Request amount |
| `Description` | `request.Description` |
| `Status` | `"Completed"` |
| `CreatedAt` | `DateTime.UtcNow` |

## Test Cases

| ID | Type | Scenario | Steps | Expected result |
|---|---|---|---|---|
| TRF-001 | Positive | Transfer by account number | Sender has balance `B`; receiver account number exists; transfer `100`. | `200 OK`; sender balance `B - 100`; receiver balance increases by 100; transaction row created; two notifications created. |
| TRF-002 | Positive | Transfer by phone number | Use receiver phone number that maps to a user with account. | Transfer succeeds; receiver account is credited. |
| TRF-003 | Positive/edge | Transfer exact sender balance | Sender balance `100`; transfer `100`. | `200 OK`; sender balance becomes `0`. |
| TRF-004 | Positive | Transfer with description | Submit notes `"Rent"`. | Transaction `Description` is `"Rent"`. |
| TRF-005 | Frontend validation | Empty recipient | Tap Next with empty recipient. | Snackbar `Please enter a recipient account`; amount screen not opened. |
| TRF-006 | Frontend validation | Invalid recipient format | Enter `123`, `abcdefgh`, or phone not starting `01`. | Snackbar `Enter an 8-digit account number or an 11-digit phone starting with 01`. |
| TRF-007 | Frontend validation | Empty/zero amount | Enter no amount or `0`. | Snackbar `Please enter a valid amount`; review screen not opened. |
| TRF-008 | Frontend validation | Amount greater than loaded balance | Account state loaded with balance `50`; enter `100`. | Snackbar `Insufficient balance`; review screen not opened. |
| TRF-009 | Frontend OTP | OTP shorter than 6 chars | Enter `12345`, tap verify. | Snackbar `Enter a valid 6-digit OTP`; API transfer not called. |
| TRF-010 | Frontend OTP | Wrong 6-digit OTP | Enter `000000`. | `OtpError`; snackbar `Invalid OTP code. Please try again.`; API transfer not called. |
| TRF-011 | Frontend OTP | Demo OTP | Enter `123456`. | OTP verified; transfer execution starts. |
| TRF-012 | Frontend fraud | Large transfer | Enter amount `10000` or higher. | `DetectFraudUseCase` throws fraud alert before API call. |
| TRF-013 | Frontend fraud | Rapid debit transactions | Have at least 3 debit transactions in last 5 minutes, then transfer. | Fraud alert before API call. |
| TRF-014 | Frontend fraud | Location outside trusted zones | Mock location outside 50 km of New York/Los Angeles, then transfer. | Fraud alert before API call. |
| TRF-015 | Backend validation | Zero/negative amount direct API | Call `POST /api/Transfer` with `amount <= 0`. | `400` with `"Amount must be greater than zero"`. |
| TRF-016 | Backend validation | Sender account missing | Valid JWT for user without account. | `400` with `"Sender account not found"`. |
| TRF-017 | Backend validation | Receiver account missing | Use account/phone not present. | `400` with `"Receiver account not found"`. |
| TRF-018 | Backend validation | Same account transfer | Use sender's own account number or phone. | `400` with `"Cannot transfer to the same account"`. |
| TRF-019 | Backend validation | Insufficient balance direct API | Sender balance `50`; transfer `100`. | `400` with `"Insufficient balance"`; no balance changes; no transaction row. |
| TRF-020 | Security | Missing token | Call `POST /api/Transfer` without token. | `401 Unauthorized`. |
| TRF-021 | Security | Invalid token | Call endpoint with invalid JWT. | `401 Unauthorized`. |
| TRF-022 | Security | Bypass frontend OTP | Call backend transfer endpoint directly without OTP. | Backend has no OTP validation; transfer can succeed if JWT and business rules pass. |
| TRF-023 | Data consistency | Exception during save | Force DB error during transfer save. | Transaction rolls back; sender/receiver balances unchanged; response `400` with `"Error during transfer: ..."`. |
| TRF-024 | Edge | Overlong description | Submit description over DB max 200 chars. | No frontend/backend prevalidation; DB may reject during save and service returns `400` with `"Error during transfer: ..."`. |
| TRF-025 | UI/data | Receiver-side history display | After successful transfer, fetch receiver transactions in Flutter. | Backend returns `type: "Credit"`, but Flutter expects `direction`; verify UI may show as debit due model mismatch. |
| TRF-026 | Security/status | Receiver user inactive | Transfer to inactive receiver user/account. | No active-status validation found in `TransferService`; expected current behavior is not blocked by service. |

## Known Issues

| Issue | Impact |
|---|---|
| Backend transfer OTP not implemented | Direct API callers can transfer with JWT only. Frontend OTP is not enforceable server-side. |
| Demo transaction OTP is hardcoded | `ApiOtpRepositoryImpl` accepts only `"123456"` for `"User Device"` and does not send real SMS/email/push OTP. |
| Fraud checks are frontend-only | Direct API calls bypass large amount, rapid transaction, and geofence checks. |
| Mock geolocation | Default current location is New York; trusted zones are New York and Los Angeles. |
| Transfer limit inconsistency | Frontend blocks `>= 10000` as fraud, but backend has no transfer maximum beyond balance. |
| No receiver/sender active-status checks in transfer service | Deactivated users may still be involved if valid tokens/accounts exist. |
| Description is not normalized | Review screen displays `"Money Transfer"` when notes are empty, but backend receives empty/omitted description from frontend wrapper. |
| Recent recipients may not populate | UI expects transaction descriptions starting `"Transfer to "`, while backend stores the user-provided description. |
| Transaction model mismatch | Backend sends `type` as debit/credit; Flutter reads `direction` and defaults to debit. Credits may render incorrectly. |
| Static receipt reference | Success screen uses hardcoded `TXN778234910`, not the backend transaction ID. |
| Bank name hardcoded | Review screen displays `"Contro Bank"`; not derived from backend. |
| Refresh-token endpoint incomplete | Backend `RefreshTokenAsync` returns `"Not implemented"`. Token refresh flow cannot complete as written. |
| API client `validateStatus` always true | 401 responses may be treated as normal responses and then thrown by `ensureSuccess`, so Dio `onError` refresh logic may not run. |
| Secrets in configuration | `appsettings.json` contains database/JWT/Stripe-looking secrets in source. This is security debt affecting all money features. |

## Current Project Status

| Category | Status |
|---|---|
| Completed | Authenticated transfer endpoint; receiver lookup by account number or phone; positive amount validation; sender/receiver account checks; same-account prevention; sufficient balance check; atomic sender debit/receiver credit/transaction insert; notifications after commit; Flutter transfer screens; frontend OTP gate; frontend fraud checks; refresh after success. |
| Partially completed | OTP and fraud controls exist only on the frontend; receipt does not use backend transaction ID; recent recipients logic does not align with backend transaction descriptions. |
| Missing | Server-side OTP; server-side fraud/velocity/location checks; transfer limits; active sender/receiver status checks; explicit DTO validation attributes; description max-length validation; backend fee model; real receipt/reference data. |
| Recommended improvements | Move OTP/fraud enforcement to backend; return transaction ID and timestamp; align transaction response field with Flutter model or update Flutter to read `type`; store structured transaction category/direction; implement refresh token; remove secrets from source; add integration tests for concurrent transfers and rollback. |

---

# Database Schema Relevant to All Three Features

| Table | Relevant columns | Notes |
|---|---|---|
| `Users` | `Id`, `FullName`, `Email`, `PhoneNumber`, `Role`, `IsActive`, `OtpCode`, `OtpExpiry`, `CreatedAt` | `PhoneNumber` is used as fallback receiver lookup in transfer. `OtpCode`/`OtpExpiry` exist but are not used by transfer/ATM services. |
| `Accounts` | `Id`, `UserId`, `AccountNumber`, `Balance`, `CreatedAt` | `Balance` is `numeric(18,2)` in migration and `decimal(18,2)` in entity annotation. One-to-one with `Users`. |
| `Transactions` | `Id`, `SenderAccountId`, `ReceiverAccountId`, `Amount`, `Description`, `Status`, `CreatedAt` | Sender and receiver account foreign keys use restrict delete behavior. `Description` max length is 200. |
| `Notifications` | `Id`, `UserId`, `Title`, `Message`, `IsRead`, `CreatedAt` | Created after money operation commit; not part of the same DB transaction in service code. |

# Cross-Feature QA Notes

| Area | QA focus |
|---|---|
| Atomicity | Verify balance updates and transaction insert commit or roll back together for ATM and transfer operations. |
| Authorization | Verify every money endpoint rejects missing and invalid JWTs. |
| Direct API bypass | Verify which frontend protections can be bypassed by direct API calls: transfer OTP, transfer fraud checks, recipient format, client balance check, and note length. |
| Transaction history | Verify backend `GET /api/Account/transactions` response and Flutter rendering. The `type`/`direction` mismatch is likely visible. |
| Notifications | Verify notifications are created after successful money operations, but do not expect money operation failure if notification insert fails. |
| Deactivated accounts | Verify behavior for tokens issued before deactivation; service-level `User.IsActive` checks are not found. |
| Concurrency | No explicit optimistic concurrency/versioning found. Concurrent withdraw/transfer tests should verify whether balances can be overspent under load. |
| Secrets/config | Do not rely on committed secrets for production. Move secrets to environment or secure secret storage. |

