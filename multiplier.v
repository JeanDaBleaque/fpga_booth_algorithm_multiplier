module multiplier #(parameter N=5) (
    input clk,
    input rstn, // (ASYNC) Before multiplication process, resetting shift registers via. RST = 0, recommended but not required.
    input start, // To start multiplication set START = 1 for at least 1 clk posedge.
    input [N-1:0] multiplier_in,
    input [N-1:0] multiplicand_in,
    output reg [2*N-1:0] product
);
    reg [2*N-1:0] product_temp;
    reg state;
    reg previousBit;
    reg [N-1:0] multiplicand_reg;
    reg [7:0] counter;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) state <= 1'b0; 
        else begin
            case (state)
            1'b0: if (start) begin // IDLE and Load State
                multiplicand_reg <= multiplicand_in;
                product_temp <= {{N{1'b0}}, multiplier_in};
                counter <= 8'b0;
                previousBit <= 1'b0;
                state <= 1'b1;
            end
            1'b1: if (!start) begin // Operation State
                if (counter < N) begin
                    if (~product_temp[0] & previousBit) begin
                        previousBit <= product_temp[0];
                        product_temp = product_temp + {multiplicand_reg, {N{1'b0}}};
                        product_temp = {product_temp[2*N-1:0], product_temp[2*N-1:1]};
                    end else if (product_temp[0] & ~previousBit) begin
                        previousBit <= product_temp[0];
                        product_temp = product_temp - {multiplicand_reg, {N{1'b0}}};
                        product_temp = {product_temp[2*N-1:0], product_temp[2*N-1:1]};
                    end else begin
                        previousBit <= product_temp[0];
                        product_temp <= {product_temp[2*N-1:0], product_temp[2*N-1:1]};
                    end
                    counter <= counter + 1;
                end else begin
                    product <= product_temp;
                    state <= 1'b0;
                end
            end else state <= 1'b0;
        endcase
        end
    end
endmodule

// Using custom shift registers - NOT OPTIMIZED (it takes too many clock cycles to calculate!)

/*module multiplier #(parameter N=5) (
    input clk,
    input rst, // Before multiplication process, resetting shift registers via. RST = 0, recommended but not required.
    input start, // To start multiplication set START = 1 for at least 1 clk posedge.
    input [N-1:0] multiplier_in,
    input [N-1:0] multiplicand_in,
    output reg [2*N-1:0] product
);
    reg [1:0] state;
    reg load;
    reg shift;
    reg [N-1:0] counter;
    reg previousBit;
    wire [2*N-1:0] product_reg;
    reg [2*N-1:0] product_load;
    shiftRegister #(.N(2*N)) product_register(
        .clk(clk),
        .rst(rst),
        .load(load),
        .shift(shift),
        .direction(1'b0),
        .pushData(product_reg[2*N-1]),
        .loadData(product_load),
        .out(product_reg)
    );
    always @(posedge clk) begin
        case (state)
            2'b00: begin
                if (start) begin
                    counter <= {N{1'b0}};
                    product_load <= {{N{1'b0}}, multiplier_in};
                    load <= 1'b1;
                    shift <= 1'b0;
                    state <= 2'b01;
                    previousBit <= 1'b0;
                end else state <= 2'b00;
            end
            2'b01: begin
                if (load & ~shift) begin
                    load <= 1'b0;
                    shift <= 1'b0;
                    state <= 2'b01;
                end else if (counter < N) begin
                    if (~product_reg[0] & previousBit) begin
                        product_load = product_reg + {multiplicand_in, {N{1'b0}}};
                        load <= 1'b1;
                        shift <= 1'b0;
                        state <= 2'b10;
                    end else if (product_reg[0] & ~previousBit) begin 
                        product_load = product_reg - {multiplicand_in, {N{1'b0}}};
                        load <= 1'b1;
                        shift <= 1'b0;
                        state <= 2'b10;
                    end else begin 
                        load <= 1'b0;
                        shift <= 1'b1;
                        state <= 2'b10;
                    end
                end else begin
                    counter <= {N{1'b0}};
                    shift <= 1'b0;
                    previousBit <= 1'b0;
                    state <= 2'b00;
                    product <= product_reg;
                end
            end
            2'b10: begin
                previousBit <= product_reg[0];
                if (load & ~shift) begin
                    load <= 1'b0;
                    shift <= 1'b1;
                    state <= 2'b10;
                end else begin
                    load <= 1'b0;
                    shift <= 1'b0;
                    state <= 2'b11;
                end
            end
            2'b11: begin
                counter <= counter + 1;
                product_load <= product_reg;
                load <= 1'b0;
                shift <= 1'b0;
                state <= 2'b01;
            end
        endcase
    end
endmodule

module shiftRegister #(parameter N=4) ( //Parallel Load
    input clk,
    input rst, // Synchronous Reset
    input load,
    input shift, // SHIFT = 0 -> Read, SHIFT = 1 -> Load Data
    input direction, // DIRECTION = 0 -> Shift Right, DIRECTION = 1 -> Shift Left
    input pushData,
    input [N-1:0] loadData,
    output reg [N-1:0] out
);
    always @(posedge clk) begin
        if (!rst) out <= 0;
        else if (load) out <= loadData;
        else begin
            if (shift) begin
                case (direction)
                    1'b0: out <= {pushData, out[N-1:1]};
                    1'b1: out <= {out[N-2:0], pushData}; 
                endcase
            end
            else begin
                out <= out;
            end
        end
    end
endmodule*/