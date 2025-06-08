`include <alu_design.v>
`define PASS 1'b1
`define FAIL 1'b0
`define no_of_testcase 92

module test_bench_alu #(parameter n=8,m=4)();
localparam test_case_width=19+(4*n)+m;
localparam response_width=test_case_width+6+(2*n);
localparam result_width=(2*n)+6;
localparam scoreboard_width=(6+n+1)+n+8+(6+2*n+1);

reg [test_case_width-1:0] curr_test_case = {test_case_width{1'b0}};
reg [test_case_width-1:0] stimulus_mem [0:`no_of_testcase-1];
reg [response_width-1:0] response_packet;

integer i,j;
reg CLK,RST,CE;
event fetch_stimulus;
reg [n-1:0] OPA, OPB;
reg [m-1:0] CMD;
reg MODE, CIN;
reg [7:0] Feature_ID;
reg [2:0] Comparison_EGL;
reg [n:0] Expected_RES;
reg err, cout, ov;
reg [n-2:0] Reserved_RES;
reg [1:0] INP_VALID;

wire [2*n-1:0] RES;
wire ERR, OFLOW, COUT;
wire [2:0] EGL;
wire [result_width-1:0] expected_data;
reg [result_width-1:0] exact_data;

demo #(n, m) dut (.opa(OPA), .opb(OPB), .cin(CIN), .clk(CLK), .rst(RST),.in_val(INP_VALID), .cmd(CMD), .ce(CE), .mode(MODE),.cout(COUT), .of(OFLOW), .res(RES),
            .g(EGL[1]), .e(EGL[2]), .l(EGL[0]), .err(ERR)
        );

        task read_stimulus(); begin
            #10 $readmemb ("newstim.txt",stimulus_mem);
        end endtask

        integer stim_mem_ptr = 0, stim_stimulus_mem_ptr = 0, fid = 0, pointer = 0;

        always @(fetch_stimulus) begin
            curr_test_case = stimulus_mem[stim_mem_ptr];
            $display("stimulus_mem data = %0b \n", stimulus_mem[stim_mem_ptr]);
            $display("packet data = %0b \n", curr_test_case);
  stim_mem_ptr = stim_mem_ptr + 1;
        end

        initial begin
            CLK = 0;
            forever #60 CLK = ~CLK;
        end

        task automatic driver(); begin
            ->fetch_stimulus;
            @(posedge CLK);
            Feature_ID = curr_test_case[(test_case_width-1)-:8];
            INP_VALID = curr_test_case[(test_case_width-9)-:2];
            OPA = curr_test_case[(test_case_width-11)-:n];
            OPB = curr_test_case[(test_case_width-11-n)-:n];
            CMD = curr_test_case[(test_case_width-11-2*n)-:m];
            CIN = curr_test_case[(test_case_width-11-2*n-m)];
            CE = curr_test_case[(test_case_width-11-2*n-m-1)];
            MODE = curr_test_case[(test_case_width-11-2*n-m-2)];
            Reserved_RES = curr_test_case[(test_case_width-11-2*n-m-3)-:n-1];
            Expected_RES = curr_test_case[(test_case_width-11-2*n-m-3-n+1)-:n+1];
            cout = curr_test_case[5];
            Comparison_EGL = curr_test_case[4:2];
            ov = curr_test_case[1];
            err = curr_test_case[0];
            $display("Driving: Feature_ID=%8b, INP_VALID=%2b, OPA=%b, OPB=%b, CMD=%b, CIN=%b, CE=%b, MODE=%b, Reserved_RES=%b, expected_result=%b, COUT=%b, comparision_EGL=%3b, OV=%b, ERR=%b", Feature_ID, INP_VALID, OPA, OPB, CMD, CIN, CE, MODE, Reserved_RES, Expected_RES, cout, Comparison_EGL, ov, err);
        end endtask

        task dut_reset(); begin
            CE = 1;
            #10 RST = 1;
            #20 RST = 0;
        end endtask

        task global_init(); begin
            curr_test_case = {test_case_width{1'b0}};
            response_packet = {test_case_width+6+(2*n+1){1'b0}};
            stim_mem_ptr = 0;
        end endtask

        task monitor(); begin
            repeat(5) @(posedge CLK);
            #5 begin
                response_packet[test_case_width-1:0] = curr_test_case;
                response_packet[test_case_width+:6] = {ERR, OFLOW, EGL, COUT};
                response_packet[test_case_width+7+:2*n] = RES;
                exact_data = {RES, COUT, EGL, OFLOW, ERR};
  $display("Monitor: RES=%b, COUT=%b, EGL=%b, OFLOW=%b, ERR=%b", RES, COUT, EGL, OFLOW, ERR);
            end end endtask

            assign expected_data = {Reserved_RES, Expected_RES, cout, Comparison_EGL, ov, err};

            reg [scoreboard_width-1:0] scb_stimulus_mem [0:`no_of_testcase-1];

            task score_board(); reg[n:0] expected_res; reg[n-2:0] reserved_res; reg[7:0] feature_id; reg[6+2*n:0] response_data; begin
                #5;
                feature_id = curr_test_case[(test_case_width-1)-:8];
                reserved_res = curr_test_case[(test_case_width-11-2*n-m-3)-:n-1];
                expected_res = curr_test_case[(test_case_width-11-2*n-m-3-n+1)-:n+1];
                response_data = response_packet[test_case_width+:2*n+6];
                $display("expected result = %b ,response data = %b", expected_data, exact_data);
                if (expected_data === exact_data) begin
                    scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0, Feature_ID, expected_data, response_data, 1'b0, `PASS};
                    $display("Test %0d PASSED", stim_stimulus_mem_ptr);
                end else begin
                    scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0, Feature_ID, expected_data, response_data, 1'b0, `FAIL};
                    $display("Test %0d FAILED", stim_stimulus_mem_ptr);
                end
                stim_stimulus_mem_ptr = stim_stimulus_mem_ptr + 1;
            end endtask

            task gen_report; integer file_id, pointer, i; begin
                file_id = $fopen("results.txt", "w");
                pointer = 0;
                while (pointer < `no_of_testcase) begin
                    $fdisplay(file_id, "Feature ID %8b : %s", scb_stimulus_mem[pointer][scoreboard_width-2 -: 8], scb_stimulus_mem[pointer][0] ? "PASS" : "FAIL");
                    pointer = pointer + 1;
                end
                $fclose(file_id);
            end endtask

            initial begin
                #10;
                $display("\n--- Starting ALU Verification ---");
                global_init();
                dut_reset();
                read_stimulus();
                for (j = 0; j <= `no_of_testcase-1; j = j + 1) begin
                    fork
                        driver();
                        monitor();
                    join
                    score_board();
                end
                gen_report();
 $fclose(fid);
                #100 $display("\n--- Verification Complete ---");
                $finish();
            end
            endmodule
