module demo #(
    parameter op_len = 8,
    parameter cmd_len = 4
)(
    input [op_len-1:0] opa, opb,
    input clk, rst, mode, ce, cin,
    input [cmd_len-1:0] cmd,
    input [1:0] in_val,
    output reg err, l, g, e, cout, of,
    output reg [2*op_len-1:0] res
);

reg signed [op_len-1:0] sign_a, sign_b;
reg [op_len-1:0] tempa, tempb;
reg [op_len-1:0] tempa_d1, tempb_d1;
reg tempcin;
reg mul_flag;

localparam bits_req = (op_len == 1) ? 1 : $clog2(op_len);
reg [bits_req-1:0] shift_val;

// First register stage
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tempa <= 0;
        tempb <= 0;
        tempcin <= 0;
        sign_a <= 0;
        sign_b <= 0;
        mul_flag <= 0;
    end else if (ce) begin
        tempa <= opa;
        tempb <= opb;
        tempcin <= cin;
        sign_a <= $signed(opa);
        sign_b <= $signed(opb);
        mul_flag <= (cmd == 4'd9 || cmd == 4'd10);
    end
end

// Second register stage for multiplication inputs
always @(posedge clk or posedge rst) begin
    if (rst) begin
        tempa_d1 <= 0;
        tempb_d1 <= 0;
    end else if (ce && mode && mul_flag) begin
        tempa_d1 <= tempa;
        tempb_d1 <= tempb;
 end else if (!mode) begin
        tempa_d1 <= 0;
        tempb_d1 <= 0;
    end
end

// Main ALU logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        res <= 0;
        err <= 0;
        l <= 0;
        g <= 0;
        e <= 0;
        cout <= 0;
        of <= 0;
    end else if (ce) begin
        res <= 0;
        err <= 0;
        l <= 0;
        g <= 0;
        e <= 0;
        cout <= 0;
        of <= 0;

        if (mode) begin
            case (in_val)
                2'b00: res <= 0;

                2'b01: case (cmd)
                    4'd4: begin
                        res[op_len:0] <= tempa + 1;
                        of <= (tempa == {op_len{1'b1}});
                    end
                    4'd5: begin
                        res[op_len:0] <= tempa - 1;
                        of <= (tempa == 0);
                    end
                    default: res <= 0;
                endcase

                2'b10: case (cmd)
                    4'd6: begin
                        res <= tempb + 1;
                        of <= (tempb == {op_len{1'b1}});
                    end
                    4'd7: begin
                        res <= tempb - 1;
  of <= (tempb == 0);
                    end
                    default: res <= 0;
                endcase

                2'b11: case (cmd)
                    4'd0: begin
                        res[op_len:0] <= tempa + tempb;
                        cout <= res[op_len];
                    end
                    4'd1: begin
                        res[op_len:0] <= tempa - tempb;
                        cout <= (tempa < tempb);
                    end
                    4'd2: begin
                        res[op_len:0] <= tempa + tempb + tempcin;
                        cout <= res[op_len];
                    end
                    4'd3: begin
                        res[op_len:0] <= tempa - tempb - tempcin;
                        cout <= (tempa >= (tempb + tempcin));
                    end
                    4'd8: begin
                        if (tempa > tempb)
                            g <= 1;
                        else if (tempa < tempb)
                            l <= 1;
                        else
                            e <= 1;
                    end
                    4'd9: res[op_len:0] <= (tempa_d1 + 1) * (tempb_d1 + 1);
                    4'd10: res <= (tempa_d1 << 1) * tempb_d1;
                    4'd11: begin
                        res[op_len:0] <= sign_a + sign_b;
                        of <= (sign_a[op_len-1] == sign_b[op_len-1]) &&(res[op_len-1] != sign_a[op_len-1]);
                    end
                    4'd12: begin
                        res[op_len:0] <= sign_a - sign_b;
                        of <= (sign_a[op_len-1] != sign_b[op_len-1]) && (res[op_len-1] != sign_a[op_len-1]);
                    end
                    default: res <= 0;
                endcase
            endcase
        end else begin
            case (in_val)
                2'b00:res<=0;
                2'b01: case (cmd)
                    4'd6: res[op_len-1:0] <= ~tempa;
   4'd8: res[op_len:0] <= tempa >> 1;
                    4'd9: res[op_len:0] <= tempa << 1;
                    default: res <= 0;
                endcase

                2'b10: case (cmd)
                    4'd7: res[op_len-1:0] <= ~tempb;
                    4'd10: res[op_len:0] <= tempb >> 1;
                    4'd11: res[op_len:0] <= tempb << 1;
                    default: res <= 0;
                endcase

                2'b11: begin
                    shift_val = tempb[bits_req-1:0];
                    case (cmd)
                        4'd0: res[op_len-1:0] <= tempa & tempb;
                        4'd1: res[op_len-1:0] <= ~(tempa & tempb);
                        4'd2: res[op_len-1:0] <= tempa | tempb;
                        4'd3: res[op_len-1:0] <= ~(tempa | tempb);
                        4'd4: res[op_len-1:0] <= tempa ^ tempb;
                        4'd5: res[op_len-1:0] <= ~(tempa ^ tempb);
                        4'd12: begin
                            err <= (|tempb[op_len-1:bits_req]) ? 1 : 0;
                            if (err)
                                res <= 0;
                            else
                                res[op_len-1:0] <= (tempa << shift_val) | (tempa >> (op_len - shift_val));
                        end
                        4'd13: begin
                            err <= (|tempb[op_len-1:bits_req]) ? 1 : 0;
                            if (err)
                                res <= 0;
                            else
                                res[op_len-1:0] <= (tempa >> shift_val) |(tempa << (op_len - shift_val));
                        end
                        default: res <= 0;
                    endcase
                end
            endcase
        end
    end else begin
        res <= 0;
        err <= 0;
        l <= 0;
        g <= 0;
        e <= 0;
  cout <= 0;
        of <= 0;
    end
end
endmodule

