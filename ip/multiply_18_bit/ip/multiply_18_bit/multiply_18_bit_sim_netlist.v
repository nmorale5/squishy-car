// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
// Date        : Fri Dec  8 17:32:28 2023
// Host        : LAPTOP-I972FERD running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               c:/Users/super/Desktop/6.2050/squishy-car/ip/multiply_18_bit/ip/multiply_18_bit/multiply_18_bit_sim_netlist.v
// Design      : multiply_18_bit
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7s50csga324-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "multiply_18_bit,mult_gen_v12_0_18,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "mult_gen_v12_0_18,Vivado 2023.1" *) 
(* NotValidForBitStream *)
module multiply_18_bit
   (CLK,
    A,
    B,
    P);
  (* x_interface_info = "xilinx.com:signal:clock:1.0 clk_intf CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME clk_intf, ASSOCIATED_BUSIF p_intf:b_intf:a_intf, ASSOCIATED_RESET sclr, ASSOCIATED_CLKEN ce, FREQ_HZ 10000000, FREQ_TOLERANCE_HZ 0, PHASE 0.0, INSERT_VIP 0" *) input CLK;
  (* x_interface_info = "xilinx.com:signal:data:1.0 a_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME a_intf, LAYERED_METADATA undef" *) input [17:0]A;
  (* x_interface_info = "xilinx.com:signal:data:1.0 b_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME b_intf, LAYERED_METADATA undef" *) input [17:0]B;
  (* x_interface_info = "xilinx.com:signal:data:1.0 p_intf DATA" *) (* x_interface_parameter = "XIL_INTERFACENAME p_intf, LAYERED_METADATA undef" *) output [35:0]P;

  wire [17:0]A;
  wire [17:0]B;
  wire CLK;
  wire [35:0]P;
  wire [47:0]NLW_U0_PCASC_UNCONNECTED;
  wire [1:0]NLW_U0_ZERO_DETECT_UNCONNECTED;

  (* C_A_TYPE = "0" *) 
  (* C_A_WIDTH = "18" *) 
  (* C_B_TYPE = "0" *) 
  (* C_B_VALUE = "10000001" *) 
  (* C_B_WIDTH = "18" *) 
  (* C_CCM_IMP = "0" *) 
  (* C_CE_OVERRIDES_SCLR = "0" *) 
  (* C_HAS_CE = "0" *) 
  (* C_HAS_SCLR = "0" *) 
  (* C_HAS_ZERO_DETECT = "0" *) 
  (* C_LATENCY = "3" *) 
  (* C_MODEL_TYPE = "0" *) 
  (* C_MULT_TYPE = "1" *) 
  (* C_OPTIMIZE_GOAL = "1" *) 
  (* C_OUT_HIGH = "35" *) 
  (* C_OUT_LOW = "0" *) 
  (* C_ROUND_OUTPUT = "0" *) 
  (* C_ROUND_PT = "0" *) 
  (* C_VERBOSITY = "0" *) 
  (* C_XDEVICEFAMILY = "spartan7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  multiply_18_bitmult_gen_v12_0_18 U0
       (.A(A),
        .B(B),
        .CE(1'b1),
        .CLK(CLK),
        .P(P),
        .PCASC(NLW_U0_PCASC_UNCONNECTED[47:0]),
        .SCLR(1'b0),
        .ZERO_DETECT(NLW_U0_ZERO_DETECT_UNCONNECTED[1:0]));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2023.1"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
KUaKzaiUy+PF6hJx6nRT61A3zj1MVbDVX6brdK11mV39kC05zIh1o5y1c5/Qs9BoLq9UL4RZ8k5f
PhBBUQzHHw+bW7ExufB5tahGiG/PbxoV1ksHXOIyYobGc92QVYyFdI0DCH3/mShH3dIPmGrdhxpS
TWsvdEw5yuZZvJEdWaA=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
GberH2b1XOkDbvTKGmSGGhU/Fy0asnk+Rz+wHciYmi1E54D3qLypHJqt74luk+uswRq5kgQw8X+V
SotRe37PYRcGPwUrz7oLVQf9h7jqBCfny6ubBFEZdHJzfKejbwONTKsoP0fV6pYvsomkz5oMp+l4
7C971VQbx8RU+E8SXuFEz9K8may1mWbEnMdOKSKWCH8RstMZfQulf4dWF6j66iYfBzMuegl2HemM
s0AHlQFWe9anszxR+LpTy691Xo08SJxLBok+RoZfe2SQGG9unFmFn3EqZdNeWWKErQbJJs8VRB26
bcTCAgiPskugXspU2E8SdZvk+xnvjtR4r4+6IQ==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
nHK/CVHR2PV0V8ZjGGHIFsN/exvygpUh8h066P7lahKCnmrPREwnWKld1lXHfh4kOhl28qi9/WDb
H3AL/4UXLmWER9kw80h5IBSw6yHNPQMv61FdqGBSfggqKYkHF3gC1FGSWA4zlii8NVPGXvlrs5RG
OgNKyncA6lM9KGVGDZM=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
l3xGeg9CwZgotBkJBFaQD5sGcp1L3pSFplSdYso7dOPw7sKIRmPxOpxGjvUbT4nBnndT7bFBhGhM
y00UOg4Oj96DGjm46YX+ESp4r0FqzCbB3uPWSHb4mYLvuZEqf++NWkODANxT+2VPhTkGVmkbR37r
xipajr8FHFniud+8ohnz/SWeVykaTY7nI04i4LH5W9/ThSzfBeNYJsRNAEFuWSz6oQ+ngpz8fUa2
PPtBXf5t/QWrb8a02bHWfIrv/8xUlcPYt5ujanJhaH8+GZq//GeaNk73C/azKONpxpHOVb7K6+vR
YfDqJ/5gMnSJFpzdS2Ki4l56QsAi5Kos8ZIpHQ==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
bz6+PTye4yzmbPqUAt58ZSSfgUFWYJUsW7WngKOl6FaQSaWmYyC6+UIEHjSJ46zGL1UkzMt7ftmb
Ygk8nZuuAwL8nTa6WsUiytgyjJGgkuS6lExFU7HkO/x+OjPOdUmVv+6QqBy+lD75r5TQsCqVbEuT
nKmyuAMIbYwxTzgGv7c5ks73KdQLQ22LzNDfPNySaJ2ov9qHF7eY81s+viQTYWhYLX3ckIYiPhy8
OOxci4isH7SuQKkPrv4NQWN9h2tUwd1mlRegrgs/lPcaRP8OT2Gp9JoBYxzxLONHC9wc39Y3fflD
Qfxw+bjglr5xGvXc9p4fE3TvvB3ArSIHcxhQJQ==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2022_10", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
IGAOeTNlmlEi+iWEJt9fUt/wm7+7Jhp06DIfcj5iM98jb7dROg5DG5mDH149JCyvhlzB2pQGs4g8
owRbbHjJoRYB4sQkdq/PCfk5lDsJXgW7D86M/V5CAaHd5TUGynMgSlKAWkZWL3ING6cHLcoPiCQb
ybfmIXg0dFCkM/ygKawGu1K1Qp6Jn62yLc3yGyGcwJlBwAejUprLmkGWJLhKxSAaZiraIPLsUPHy
8+nj9+hjDomSqlXxrCaU/P3c+7QJ/mkXWkQ1TvTMJrpyyB3SkvGY16rf0gcS4edq0SXRhA0OuVum
UD2b8sdP6zrkXxJjOIGJFBtBC5FWBDJva+lAdg==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
jJGb0fDk5wJq4PUkUAzmDXiu5nBx5xFPbQ8faDe0yxazQT3L4+3WMgo0SAG3mFDI4UXC7gx837fK
YBV37OMFtaQ/aVqti1/IXwqABxZCM5fd+YTDMuOJLvTv9oXXzTSrasGsOgExG5/pDDvhP/s8MQA+
Tw4xAaJa79xQmNVSvmWGyecwvlIEdT5hmHfecs82lPjJvtTcieProVnUMwcU8pRk3q2m5+5g7vYV
5bL5F7skGgy1dkt26i776w/BzljMXPUlShXC11Z3OHKdBIEnT5oB4NpGDTww5RGJLxywsbkCRMkk
XiYCWJgmeQjmHUZ1uIe0JqyxsvKV8asjI1YUUw==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
N3JiRa6NhBC3KawTT6EPvyj//Pt745fGHnOBVgu+8uJp65V7lTVeR1v0adczGA4hegoxI6ymmmaZ
ZtFA4xF2jY3/Fzah91XS2SWiW2NqzYQrozAtG9FJ+HzgAkeX/Sy9GdDVrzgYcZW7oalsBuJ7sulr
+l3dc++GnFkq+IZfS4677VmmzQW4/ZASU9kNE9r2rIR0RN5jT9HWwCCxarCqTvQHnJRsbYG2725H
/RQC+pFpN3sLfE//Vu6pjC2g6LfYE34jpdeb8yN5GkU6ybRZqTOQLtEN8N304pGmRmBfAOWyl6VA
d8txy7ejPGaiu1Hwt+MVXJo4po7vVHRmpLvtP3CKLewHfCG+UykdYqrT8IdaxypDjxAk+puc9jsc
P69yR/HjjWoIBlQ5btY3+sKJe3SardsSOx/55XhjMfWhM6O1VkDGQ8R77WzL9/dP3N+n3zp3hI/K
Og4aveX1HAXDBbbGF89RNpZ4e4elDwDN8o7ZbTI1nZz4y+G7S1GzLg5X

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
F47PXxCoL2GWTplpURu09s8RDF1DBSe6qbHV7iO4X3sgsSC775pbojdSvgqaCuFdgk0D/YZ9UvQQ
AShB+KYwaK+JndRHv8siGXzdvud0Ls+Ls96QKnnoo6Sp5vtX5UwZA+O5bT0kE31HrwGrw9W2y+CA
tdV1E9RQ4Wp6UaootE0aZNFZtDyocXcL0j8J0RbA5CGktFfcB5pNUEl99wvwJCE+PlTnakInMBhn
J8SxJ2OnAx1VKPi1Mr2boRa/S9QiM0I6EKmjgG+p6mbX2uDX56RyDgZ7RThkWmKSLTjV9ylE7v7l
irdRR1Yb+h6xiyssSQEg81ZGk0l2Tn0gTyPulA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
WEZqRIhpAKcsI+CNAFRhEIAJfFQ5+XUXAZNJehQr+ELeCwSQlQVsYF5NlFmZDcG9RNPN90qV88Wd
7H4NFrZyBQ9PbrwMk/mxmD4jtPXq1mVtE9CQhg+9udvqLraKnvFgjKEvNqC2Vu4xJZY+941Gx2bC
qdT8Vc+CFLK3yriXtWsZ+f5KehTK0+TypitN5JPNyq8YLCsWGHhH4ww23wsYZI0yiVgEF94Da6A1
F434TFOcxoRRvF0N6E8GYqafClX0vBpVhcrx9UoQ0uW+iXjnhGTB487f9O3Z0C+jLI/Icwxdam6l
pumgb/m9Y+jB+CzhU4g91yjJPqG4ZLKJLCaRvg==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
zmedWo9hMlAeLSjj4cCsHAOgNqrFybQV8NYfHoSR0iSQ8AEGWLoS+jLQVe/+uvMrhGxFk6I2Cd8B
S+UxDiNn2mXLcYKEMWQYKvWj/qfOzia0O9qnrntrwMh06Y6Jo3omb7Kd9CAJuwDcsmhGBQ5GzmUz
fq7CFMrtKb3oBVjjfKAHbylgBzoun1PyIKWz+Qrwe4qxajBtF42EoVABwd/ww1Q9bZiDAg4ujrAI
yFULJIhbJxOUSM5Qp6zz6TzmYqMQkDMYogr8a6QkAryFHf6yKAQOb5jWy5tse5tDwN86DGIAERvC
ciMlg9KF3cr/bQYl6Y98ucyLUSkvK21pIOZNag==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 11088)
`pragma protect data_block
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
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
