`ifndef RAND_LFSR_VH
`define RAND_LFSR_VH
// -----------------------------------------------------------------------------
// Deterministic 32-bit LFSR PRNG for structured random TBs (portable).
// Polynomial: x^32 + x^22 + x^2 + x + 1. Use SEED plusarg for reproducibility.
// -----------------------------------------------------------------------------
function [31:0] lfsr_next;
  input [31:0] state;
  reg feedback;

  begin
    feedback  = state[31] ^ state[21] ^ state[1] ^ state[0];
    lfsr_next = {state[30:0], feedback};
  end
endfunction

//////////////////////////////////////////////////////////////////

function [31:0] rand32;
  input [31:0] state;

  begin
    rand32 = lfsr_next(state);
  end
endfunction

/////////////////////////////////////////////////////////////////////

function [31:0] rand_range;
  input [31:0] state;
  input [31:0] max_plus1; // returns [0..max_plus1-1]
  reg [31:0] v;

  begin
    v = lfsr_next(state);
    if (max_plus1 == 0) rand_range = 0;
    else rand_range = v % max_plus1;
  end
endfunction

`endif
