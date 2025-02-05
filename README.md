# Overview

This project evaluates whether a test distribution aligns with an expected (control) distribution by comparing their cumulative distribution functions (CDFs).

## Methodology

Two key calculations determine whether the test distribution meets expectations:

1. Kolmogorov-Smirnov (K-S) Test
The Kolmogorov-Smirnov test is a non-parametric statistical test that assesses whether two distributions originate from the same underlying distribution. It calculates the maximum absolute difference between the two CDFs at any given point.

<img width="310" alt="image" src="https://github.com/user-attachments/assets/f4dbdcb3-f589-4048-8252-9d1a280abb52" />

Example Results

Pass Case:
In the first graph below, the control (expected) CDF is shown in white, and the test CDF in red. The K-S test returns a value of 0.1158, meaning the largest observed difference between the two CDFs is 11.58 percentage points. Based on scenario testing, a tolerance of 0.15 (15%) provides reasonable results, so this test passes.

Fail Case:
In the second graph, the K-S test returns 0.4434, indicating a significant deviation between the two distributions. As a result, this test fails.

<img width="447" alt="image" src="https://github.com/user-attachments/assets/af284365-6630-489f-a02d-2aedd33d3586" />

<img width="454" alt="image" src="https://github.com/user-attachments/assets/f5cc0593-1065-4f4a-a696-250537cc02fc" />

To ensure statistical significance, the OS/SDK/device/chipset sample size must be sufficiently large. This is evaluated using a p-value threshold of < 0.05. The coefficient used for calculating the p-value in this context is 0.01.

For further reference, see the attached kstest.pdf file, which contains a detailed breakdown of the calculations and results.
