using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BankE.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddCardNumberAndCvv : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CardNumber",
                table: "Cards",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "Cvv",
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
                value: "$2a$11$iZefKq5DOur/VEVOTtps6.BImKiykMI4W6r7AkET70oHVS4opuemS");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CardNumber",
                table: "Cards");

            migrationBuilder.DropColumn(
                name: "Cvv",
                table: "Cards");

            migrationBuilder.UpdateData(
                table: "Users",
                keyColumn: "Id",
                keyValue: 1,
                column: "PasswordHash",
                value: "$2a$11$mn/K/xmyWs.butKA4qUJeuL4yOGBUtrfznLK9/TAlVBtjSaoEE8rS");
        }
    }
}
