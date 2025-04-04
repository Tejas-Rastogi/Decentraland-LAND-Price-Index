# Decentraland Primary LAND Sales Index
This project creates a daily LAND sales index to measure the market performance of primary sales in Decentraland, a blockchain-based virtual reality platform, from January 2020 to December 2024. Primary sales reflect initial demand for virtual LAND directly from the platform, offering a clean measure of market activity without secondary market speculation. Using hedonic regression, monthly index construction, and daily disaggregation, the index captures price trends in Decentraland’s primary market, enabling high-frequency analysis like short-term forecasting and market monitoring for investors, developers, and researchers.

Methodology:
The analysis involves three steps:

Hedonic Regression: A log-linear hedonic regression model estimates quality-adjusted prices for 2,586 primary LAND sales, controlling for parcel characteristics (e.g., location, proximity to roads/plazas) and using monthly time dummies to isolate price trends. The model has a high fit (R² = 0.789).

Monthly Hedonic Index: Monthly time dummy coefficients are used to build a quality-adjusted price index, normalized to 100 in January 2020. The index ranges from 45.7 (Sep-24) to 1830.2 (Dec-21), showing volatility, with a peak in December 2021 (1,730% increase) and a low in September 2024 (54% decrease).

Daily Disaggregation: The monthly index is disaggregated into a daily index using the Chow-Lin method, with a daily indicator based on imputed average sale prices (using Cubic Spline with Noise). The daily index ranges from 40.27 to 2136.28, aligning with monthly trends (MAPE = 1.23%).
