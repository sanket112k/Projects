# APB_ALU IP — World-Class Deliverables Index

This document is the **master index** of what is delivered in this IP package. Use it for signoff, handoff, and integration planning. See also [README](../README.md).

**IP name:** APB_ALU  
**Version:** See root [VERSION](../VERSION) (e.g. 1.0.0)  
**Language:** Verilog-2001 (RTL and testbenches)

---

## 1. RTL (Source)

| Deliverable        | Path              | Description |
|--------------------|-------------------|-------------|
| ALU core           | `rtl/alu_core.v`  | Combinational ALU: 10 ops, flags Z/N/C/V, illegal detection |
| APB register file  | `rtl/apb_regs.v`  | APB3 regs: W1P start, W1C done, PSLVERR on illegal addr |
| Top-level          | `rtl/apb_alu_top.v` | Regs + ALU + 1-cycle execute FSM |
| Opcode/flag header | `rtl/alu_pkg.vh`  | Shared defines for RTL and TBs |
| RTL file list      | `rtl/files.f`    | Tool flow file list (one path per line) |

**Parameters:** `DW` (data width, default 32). Package validated at DW=32.

---

## 2. Verification (Self-Checking TBs)

| Deliverable     | Path               | Description |
|-----------------|--------------------|-------------|
| ALU smoke       | `tb/tb_alu_smoke.v`   | Directed tests; scoreboard compare |
| ALU regression | `tb/tb_alu_regress.v` | LFSR, operand bias, opcode weighting, quota; coverage |
| APB smoke      | `tb/tb_apb_smoke.v`   | BFM tasks; compare vs reference; illegal-addr check |
| APB regression | `tb/tb_apb_regress.v` | Random + negative (illegal addr, double-start, write-while-busy, etc.) |
| Scoreboard     | `tb/scoreboard.v`     | Reference model for result/flags/illegal |
| Coverage       | `tb/coverage_surrogate.vh` | Counter-based functional coverage (per-op, flags, overflow, shift, illegal) |
| LFSR           | `tb/rand_lfsr.vh`     | Deterministic PRNG for regression |

**How to run:** `make smoke`, `make regress_quick` (one-seed fast), `make regress_alu`, `make regress_apb`, `make regress_all`. Regress TBs support optional `+DUMP_VCD` for debug waveforms. See `make help` and **04_verification_plan.md**.

---

## 3. Documentation

| Doc                    | Path                        | Purpose |
|------------------------|-----------------------------|---------|
| **This index**         | `docs/00_deliverables.md`   | Master deliverables list |
| IP specification       | `docs/01_ip_spec.md`        | Features, interfaces, execution model, illegal cases |
| Register map           | `docs/02_register_map.md`   | Offsets, access, reset, W1P/W1C |
| Integration guide      | `docs/03_integration_guide.md` | Hookup, software sequence, caveats |
| Verification plan      | `docs/04_verification_plan.md` | Tiers, exit criteria, debug workflow, coverage |
| Traceability matrix    | `docs/05_testcase_matrix.md`  | Feature → test mapping |
| Release checklist      | `docs/06_release_checklist.md` | Pre-release signoff |
| CI                     | `docs/07_ci.md`             | GitHub Actions sample (smoke) |
| Known limitations      | `docs/08_known_limitations.md` | Constraints and caveats |
| Quick reference        | `docs/09_quick_reference.md`   | One-page reg map + sw sequence + targets |
| Glossary               | `docs/10_glossary.md`       | APB, W1P/W1C, flags, verification terms |
| Troubleshooting        | `docs/11_troubleshooting.md` | Common issues and resolution |
| Tool versions          | `docs/12_tool_versions.md`  | Validated toolchain (iverilog, make) |
| Extending the IP       | `docs/13_extending.md`     | Add opcode, add test, file list, other flows |
| Workshop Gemini prompt | `docs/workshop_gemini_prompt.md` | Prompt for generating world-class workshop slides (copy into Gemini) |

---

## 4. Scripts & Automation

| Item        | Path                    | Description |
|-------------|-------------------------|-------------|
| Makefile    | `Makefile`               | smoke, regress_quick, regress_alu/apb/all, lint, clean, help |
| Lint script | `scripts/run_lint.sh`    | make lint |
| Smoke script| `scripts/run_smoke.sh`   | clean + smoke; logs in reports/ |
| Quick script| `scripts/run_quick.sh`   | clean + lint + smoke + regress_quick (fast signoff) |
| Regress script | `scripts/run_regress.sh` | clean + regress_all; logs in reports/ |
| Cov script  | `scripts/run_verilator_cov.sh` | Placeholder for optional Verilator coverage |
| CI workflow | `ci/github_actions.yml`   | Sample: install iverilog, lint + smoke |

---

## 5. Version & Changelog

| Item      | Path           | Description |
|-----------|----------------|-------------|
| Version   | `VERSION`      | Single line, e.g. 1.0.0 |
| Changelog | `CHANGELOG.md` | Version history and scope per release |

---

## 6. Signoff Criteria (World-Class)

Before release or handoff, ensure:

1. **RTL** — Clean compile (no unreviewed warnings); Lint-clean if lint target used.
2. **Smoke** — `make smoke` PASS.
3. **Regression** — `make regress_all` PASS for default seeds (e.g. 1..10).
4. **Docs** — All docs in §3 updated; release checklist (06) and known limitations (08) reviewed.
5. **Reproducibility** — Failures include seed and index for deterministic replay.

See **06_release_checklist.md** for the full checklist.

---

## 7. Directory Map

```
apb_alu_ip_worldclass/
├── VERSION
├── CHANGELOG.md
├── LICENSE
├── README.md
├── Makefile
├── rtl/
│   ├── alu_core.v
│   ├── alu_pkg.vh
│   ├── apb_regs.v
│   ├── apb_alu_top.v
│   └── files.f
├── tb/
│   ├── tb_alu_smoke.v
│   ├── tb_alu_regress.v
│   ├── tb_apb_smoke.v
│   ├── tb_apb_regress.v
│   ├── scoreboard.v
│   ├── coverage_surrogate.vh
│   └── rand_lfsr.vh
├── docs/
│   ├── 00_deliverables.md
│   ├── 01_ip_spec.md
│   ├── 02_register_map.md
│   ├── 03_integration_guide.md
│   ├── 04_verification_plan.md
│   ├── 05_testcase_matrix.md
│   ├── 06_release_checklist.md
│   ├── 07_ci.md
│   ├── 08_known_limitations.md
│   ├── 09_quick_reference.md
│   ├── 10_glossary.md
│   ├── 11_troubleshooting.md
│   ├── 12_tool_versions.md
│   ├── 13_extending.md
│   └── workshop_gemini_prompt.md
├── scripts/
│   ├── run_lint.sh
│   ├── run_smoke.sh
│   ├── run_quick.sh
│   ├── run_regress.sh
│   └── run_verilator_cov.sh
└── ci/
    └── github_actions.yml
```

Generated artifacts (not in repo): `sim_*`, `*.vcd`, `reports/`. See `.gitignore`.
