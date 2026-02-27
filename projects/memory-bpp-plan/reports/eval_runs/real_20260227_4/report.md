# Memory Evaluation Report

gate_result: NO_GO

## Group Metrics

| Group |   N | Success | FirstTurn | UsefulCitation | IrrelevantRecall | AvgInputTokens | P95LatencyMs | LongPollution |
| ----- | --: | ------: | --------: | -------------: | ---------------: | -------------: | -----------: | ------------: |
| G0    |   5 | 100.00% |   100.00% |          0.00% |            0.00% |        10638.0 |     176302.0 |         0.00% |
| G1    |   5 |  60.00% |    60.00% |          0.00% |            0.00% |        13850.6 |     124060.0 |         0.00% |
| G2    |   5 |  80.00% |    80.00% |          0.00% |            0.00% |        14179.0 |     172031.0 |         0.00% |
| G3    |   5 |  40.00% |    40.00% |         28.57% |           71.43% |        11822.2 |     159427.0 |         0.00% |

## Deltas

- G2 vs G0 success delta: -20.00%
- G2 vs G0 irrelevant recall delta: 0.00%
- G3 vs G2 success delta: -40.00%
- G3 vs G2 long pollution delta: 0.00%
- G2 vs G0 input token growth: 33.29%
- G2 vs G0 p95 latency growth: -2.42%

## Confidence Intervals (Bootstrap 95%)

- G2 vs G0 success delta 95% CI: [-60.00%, 0.00%]
- G3 vs G2 success delta 95% CI: [-100.00%, 20.00%]

## Gate Checks

- [FAIL] g2_success_vs_g0: G2-G0 success delta -20.00% (required >= 8.00%)
- [PASS] g2_irrelevant_recall_vs_g0: G2-G0 irrelevant recall delta 0.00% (required <= 2.00%)
- [FAIL] g3_success_vs_g2: G3-G2 success delta -40.00% (required >= 3.00%)
- [PASS] g3_long_pollution_vs_g2: G3-G2 long pollution delta 0.00% (required <= 0.00%)
- [FAIL] token_growth_limit: G2-G0 input token growth 33.29% (required <= 20.00%)
- [PASS] latency_growth_limit: G2-G0 p95 latency growth -2.42% (required <= 15.00%)
