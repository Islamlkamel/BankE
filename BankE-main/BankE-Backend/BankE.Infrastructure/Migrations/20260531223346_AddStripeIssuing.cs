using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BankE.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddStripeIssuing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CVV",
                table: "Cards");

            migrationBuilder.DropColumn(
                name: "CardNumber",
                table: "Cards");

            migrationBuilder.DropColumn(
                name: "ExpiryDate",
                table: "Cards");

            migrationBuilder.AddColumn<string>(
                name: "Brand",
                table: "Cards",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<int>(
                name: "ExpiryMonth",
                table: "Cards",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "ExpiryYear",
                table: "Cards",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Last4",
                table: "Cards",
                type: "character varying(4)",
                maxLength: 4,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Status",
                table: "Cards",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "StripeCardId",
                table: "Cards",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                column: "PasswordHash",
                value: "$2a$11$mn/K/xmyWs.butKA4qUJeuL4yOGBUtrfznLK9/TAlVBtjSaoEE8rS");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Brand",
                table: "Cards");

            migrationBuilder.DropColumn(
                name: "ExpiryMonth",
                table: "Cards");

            migrationBuilder.DropColumn(
                name: "ExpiryYear",
                table: "Cards");

            migrationBuilder.DropColumn(
                name: "Last4",
                table: "Cards");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "Cards");

            migrationBuilder.DropColumn(
                name: "StripeCardId",
                table: "Cards");

            migrationBuilder.AddColumn<string>(
                name: "CVV",
                table: "Cards",
                type: "character varying(3)",
                maxLength: 3,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "CardNumber",
                table: "Cards",
                type: "character varying(16)",
                maxLength: 16,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ExpiryDate",
                table: "Cards",
                type: "character varying(5)",
                maxLength: 5,
                nullable: false,
                defaultValue: "");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                column: "PasswordHash",
                value: "$2a$11$yvCzIpEdWOo9465RU73xn.DpuNyEdb0WgBYq.4myEl/LRuXfUQIu2");
        }
    }
}
