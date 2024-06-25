module tt_um_seven_segment_display (
    input wire clk,
    input wire reset,
    input wire [5:0] random_number,
    output reg [6:0] seg,  // Seven segment output
    output reg [3:0] an    // Anode control for 4 digits
);
    reg [3:0] digits [3:0]; // Array to store individual digits
    reg [1:0] digit_sel;    // Digit selection
    reg [3:0] current_digit; // Current digit to display

    // Segment encoding for digits 0-9
    always @(*) begin
        case (current_digit)
            4'd0: seg = 7'b1111110;
            4'd1: seg = 7'b0110000;
            4'd2: seg = 7'b1101101;
            4'd3: seg = 7'b1111001;
            4'd4: seg = 7'b0110011;
            4'd5: seg = 7'b1011011;
            4'd6: seg = 7'b1011111;
            4'd7: seg = 7'b1110000;
            4'd8: seg = 7'b1111111;
            4'd9: seg = 7'b1111011;
            default: seg = 7'b0000000; // Default blank
        endcase
    end

    // Break down random number into digits
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digits[0] <= 0;
            digits[1] <= 0;
            digits[2] <= 0;
            digits[3] <= 0;
        end else begin
            digits[0] <= random_number % 10;
            digits[1] <= (random_number / 10) % 10;
            digits[2] <= (random_number / 100) % 10;
            digits[3] <= (random_number / 1000) % 10;
        end
    end

    // Display digit selection and control
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            digit_sel <= 0;
            an <= 4'b1111;
        end else begin
            digit_sel <= digit_sel + 1;
            an <= 4'b1111;
            an[digit_sel] <= 0;
            current_digit <= digits[digit_sel];
        end
    end
endmodule

module tt_um_dice_roller (
    input wire clk,
    input wire reset,
    input wire [7:0] dip_switch, // 8-bit DIP switch input
    output wire [6:0] seg,  // Seven segment output
    output wire [3:0] an    // Anode control for 4 digits
);
    reg [4:0] lfsr;
    wire feedback;
    reg [5:0] random_number; // 6-bit output to handle the sum of the largest dice roll and modifier

    wire [2:0] dice_type;
    wire [4:0] modifier;

    // Assign DIP switch inputs to dice_type and modifier
    assign dice_type = dip_switch[7:5];
    assign modifier = dip_switch[4:0];

    // Define the feedback polynomial x^5 + x^3 + 1
    assign feedback = lfsr[4] ^ lfsr[2];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= 5'b1; // LFSR should never be zero
        end else begin
            lfsr <= {lfsr[3:0], feedback}; // Shift left and insert feedback
        end
    end

    // Generate random number based on dice type and add modifier
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            random_number <= 6'd1; // Initial value between 1 and max dice value
        end else begin
            case (dice_type)
                3'b000: random_number <= (lfsr % 4) + 1 + modifier;   // d4 + modifier
                3'b001: random_number <= (lfsr % 6) + 1 + modifier;   // d6 + modifier
                3'b010: random_number <= (lfsr % 8) + 1 + modifier;   // d8 + modifier
                3'b011: random_number <= (lfsr % 10) + 1 + modifier;  // d10 + modifier
                3'b100: random_number <= (lfsr % 12) + 1 + modifier;  // d12 + modifier
                3'b101: random_number <= (lfsr % 20) + 1 + modifier;  // d20 + modifier
                default: random_number <= 6'd1 + modifier;            // Default to 1 + modifier
            endcase
        end
    end

    // Instantiate the seven segment display module
    seven_segment_display display (
        .clk(clk),
        .reset(reset),
        .random_number(random_number),
        .seg(seg),
        .an(an)
    );
endmodule
