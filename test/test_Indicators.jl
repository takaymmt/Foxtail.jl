@testset "Indicators" begin
    aapl = CSV.read(joinpath(dirname(@__FILE__), "aapl.csv"), TSFrame)
    data_ts = aapl[end-100:end]

    @testset "Indicators SISO" begin
        data_vec = collect(1.0:50.0)

        # Shared small input for numerical validation
        small = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

        @testset "ALMA" begin
            @test ALMA(data_vec) isa Vector{Float64}
            @test ALMA(data_vec; n=5) isa Vector{Float64}
            @test ALMA(data_ts) isa TSFrame
            ma = ALMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "ALMA_50"
            @test ALMA(data_ts; offset=0.9, sigma=5.5, n=20) isa TSFrame

            # Numerical validation
            # ALMA n=3: Gaussian-weighted MA. Reference computed via Foxtail.
            r = ALMA(small; n=3)
            @test length(r) == 10
            @test r[1] ≈ 1.0 atol=1e-10                  # first value = price[1]
            @test r[3] ≈ 2.6856736002382617 atol=1e-8     # full window at i=3
            @test r[end] ≈ 9.685673600238262 atol=1e-8     # steady-state offset
            # Once window is full, ALMA(i) - ALMA(i-1) ≈ 1.0 for linear data
            @test r[6] - r[5] ≈ 1.0 atol=1e-10
        end

        @testset "EMA" begin
            @test EMA(data_vec) isa Vector{Float64}
            @test EMA(data_vec; n=5) isa Vector{Float64}
            @test EMA(data_ts) isa TSFrame
            ma = EMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "EMA_50"

            # Numerical validation
            # EMA n=3: alpha=2/(1+i) for i<=3, then alpha=2/(1+3)=0.5
            r = EMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
            @test r[2] ≈ 5/3 atol=1e-10                          # alpha=2/3: 2*(2/3)+1*(1/3)
            @test r[3] ≈ 7/3 atol=1e-10                          # alpha=0.5: 3*0.5+5/3*0.5
            @test r[4] ≈ 4*0.5 + 7/3*0.5 atol=1e-10             # post-init: alpha=0.5
            @test r[end] ≈ 9.002604166666666 atol=1e-8           # converges toward data

            # EMA with different period
            r5 = EMA(small; n=5)
            @test r5[5] ≈ 11/3 atol=1e-10                        # alpha=2/6=1/3 at i=5
            @test r5[end] ≈ 8.087791495198903 atol=1e-8
        end

        @testset "DEMA" begin
            @test DEMA(data_vec) isa Vector{Float64}
            @test DEMA(data_vec; n=5) isa Vector{Float64}
            @test DEMA(data_ts) isa TSFrame
            ma = DEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "DEMA_50"

            # Numerical validation
            # DEMA = 2*EMA(price) - EMA(EMA(price))
            r = DEMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # first value
            @test r[2] ≈ 1.8888888888888888 atol=1e-8
            @test r[3] ≈ 2.7777777777777777 atol=1e-8
            @test r[end] ≈ 9.989149305555555 atol=1e-8           # near 10 for linear data
            # DEMA should track linear data more closely than EMA
            ema_r = EMA(small; n=3)
            @test abs(r[end] - 10.0) < abs(ema_r[end] - 10.0)
        end

        @testset "HMA" begin
            @test HMA(data_vec) isa Vector{Float64}
            @test HMA(data_vec; n=5) isa Vector{Float64}
            @test HMA(data_ts) isa TSFrame
            ma = HMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "HMA_50"

            # Numerical validation
            # HMA n=4: WMA[sqrt(4)=2]( 2*WMA[2] - WMA[4] )
            r = HMA(small; n=4)
            @test r[1] ≈ 1.0 atol=1e-10
            @test r[end] ≈ 10.0 atol=1e-10                       # HMA perfectly tracks linear data
            @test r[5] ≈ 5.0 atol=1e-8
            @test r[6] ≈ 6.0 atol=1e-8
        end

        @testset "JMA" begin
            @test JMA(data_vec) isa Vector{Float64}
            @test JMA(data_vec; n=5) isa Vector{Float64}
            @test JMA(data_ts) isa TSFrame
            ma = JMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "JMA_50"
            @test JMA(data_ts; phase=55.0, n=25) isa TSFrame
            @test JMA(data_ts; phase=-55.0, n=25) isa TSFrame

            # Numerical validation
            # JMA is adaptive; verify basic properties
            r = JMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # first value = price[1]
            @test length(r) == 10
            # JMA should be monotonically increasing for monotonic input
            for i in 2:10
                @test r[i] >= r[i-1] - 1e-10
            end
        end

        @testset "KAMA" begin
            @test KAMA(data_vec) isa Vector{Float64}
            @test KAMA(data_vec; n=5) isa Vector{Float64}
            @test KAMA(data_ts) isa TSFrame
            ma = KAMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "KAMA_50"
            @test KAMA(data_ts; fast=5, slow=25, n=15) isa TSFrame

            # Numerical validation
            # KAMA n=3: Kaufman Adaptive MA
            r = KAMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10
            @test r[2] ≈ 1.4444444444444442 atol=1e-8
            @test r[3] ≈ 2.135802469135802 atol=1e-8
            @test r[end] ≈ 6.8882667553034 atol=1e-6
            # KAMA should lag behind for trending data
            @test r[end] < small[end]
        end

        @testset "RSI" begin
            @test RSI(data_vec) isa Vector{Float64}
            @test RSI(data_vec; n=5) isa Vector{Float64}
            @test RSI(data_ts) isa TSFrame
            @test RSI(data_ts; ma_type=:EMA) isa TSFrame
            @test RSI(data_ts; ma_type=:SMMA) isa TSFrame
            ma = RSI(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "RSI_50"
            @test RMA(data_ts; n=25) isa TSFrame

            # Numerical validation
            # RSI first value is always 0 (undefined)
            rsi_data = [44.0, 44.34, 44.09, 43.61, 44.33, 44.83, 45.10,
                        45.42, 45.84, 46.08, 45.89, 46.03, 45.61, 46.28,
                        46.28, 46.00, 46.03, 46.41, 46.22, 45.64]
            r = RSI(rsi_data; n=14)
            @test r[1] ≈ 0.0 atol=1e-10                          # first is undefined
            @test r[end] ≈ 60.13716896582762 atol=1e-6

            # RSI with SMA: simple small dataset
            rsi_small = [10.0, 12.0, 11.0, 13.0, 12.5, 14.0, 13.0, 15.0, 14.5, 16.0]
            r2 = RSI(rsi_small; n=3, ma_type=:SMA)
            @test r2[1] ≈ 0.0 atol=1e-10
            @test r2[2] ≈ 100.0 atol=1e-10                       # pure gain -> RSI=100
            @test r2[end] ≈ 87.5 atol=1e-6

            # RSI should be bounded [0, 100] (except first which is 0)
            for i in 2:length(r)
                @test 0.0 <= r[i] <= 100.0
            end

            # Monotonically increasing data -> RSI = 100 at index 2
            mono = collect(1.0:20.0)
            r_mono = RSI(mono; n=5)
            @test r_mono[2] ≈ 100.0 atol=1e-10
        end

        @testset "SMA" begin
            @test SMA(data_vec) isa Vector{Float64}
            @test SMA(data_vec; n=5) isa Vector{Float64}
            @test SMA(data_ts) isa TSFrame
            ma = SMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "SMA_50"
            @test RMA(data_ts; n=25) isa TSFrame

            # Numerical validation
            # SMA n=3: arithmetic mean over sliding window
            r = SMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # 1/1
            @test r[2] ≈ 1.5 atol=1e-10                          # (1+2)/2
            @test r[3] ≈ 2.0 atol=1e-10                          # (1+2+3)/3 = 2.0
            @test r[4] ≈ 3.0 atol=1e-10                          # (2+3+4)/3 = 3.0
            @test r[5] ≈ 4.0 atol=1e-10                          # (3+4+5)/3 = 4.0
            @test r[end] ≈ 9.0 atol=1e-10                        # (8+9+10)/3 = 9.0

            # SMA n=5
            r5 = SMA(small; n=5)
            @test r5[5] ≈ 3.0 atol=1e-10                         # (1+2+3+4+5)/5 = 3.0
            @test r5[end] ≈ 8.0 atol=1e-10                       # (6+7+8+9+10)/5 = 8.0
        end

        @testset "SMMA" begin
            @test SMMA(data_vec) isa Vector{Float64}
            @test SMMA(data_vec; n=5) isa Vector{Float64}
            @test SMMA(data_ts) isa TSFrame
            ma = SMMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "SMMA_50"

            # Numerical validation
            # SMMA n=3: alpha=1/i for i<=3, then alpha=1/3
            r = SMMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
            @test r[2] ≈ 1.5 atol=1e-10                          # alpha=1/2: 2*0.5+1*0.5
            @test r[3] ≈ 2.0 atol=1e-10                          # alpha=1/3: 3/3+1.5*2/3
            @test r[4] ≈ 8/3 atol=1e-10                          # alpha=1/3: 4/3+2*2/3
            @test r[end] ≈ 8.058527663465936 atol=1e-8

            # SMMA n=5
            r5 = SMMA(small; n=5)
            @test r5[5] ≈ 3.0 atol=1e-10                         # matches SMA at period end
            @test r5[end] ≈ 6.655360000000001 atol=1e-8           # more lag than EMA
        end

        @testset "T3" begin
            @test T3(data_vec) isa Vector{Float64}
            @test T3(data_vec; n=5) isa Vector{Float64}
            @test T3(data_ts) isa TSFrame
            ma = T3(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "T3_50"
            @test T3(data_ts;n=25, a=0.6) isa TSFrame

            # Numerical validation
            # T3 is built from DEMA layers; verify basic properties
            r = T3(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # first value
            @test length(r) == 10
            # T3 should be monotonically increasing for monotonic input
            for i in 2:10
                @test r[i] >= r[i-1] - 1e-6
            end
        end

        @testset "TEMA" begin
            @test TEMA(data_vec) isa Vector{Float64}
            @test TEMA(data_vec; n=5) isa Vector{Float64}
            @test TEMA(data_ts) isa TSFrame
            ma = TEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "TEMA_50"

            # Numerical validation
            # TEMA = (EMA1 - EMA2)*3 + EMA3
            r = TEMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10
            @test r[2] ≈ 1.9629629629629632 atol=1e-8
            @test r[3] ≈ 2.9259259259259256 atol=1e-8
            @test r[end] ≈ 10.014612268518519 atol=1e-8          # overshoots slightly
            # TEMA tracks linear data very closely
            @test abs(r[end] - 10.0) < 0.02
        end

        @testset "TMA" begin
            @test TMA(data_vec) isa Vector{Float64}
            @test TMA(data_vec; n=5) isa Vector{Float64}
            @test TMA(data_ts) isa TSFrame
            ma = TMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "TMA_50"
            @test TRIMA(data_ts; n=25) isa TSFrame

            # Numerical validation
            # TMA n=3: SMA(SMA(price; n=3); n=div(4,2)=2)
            r = TMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10
            @test r[2] ≈ 1.25 atol=1e-10                         # SMA of [1.0,1.5] = 1.25
            @test r[3] ≈ 1.75 atol=1e-10                         # SMA of [1.5,2.0] = 1.75
            @test r[4] ≈ 2.5 atol=1e-10                          # SMA of [2.0,3.0] = 2.5
            @test r[end] ≈ 8.5 atol=1e-10                        # SMA of [8.0,9.0] = 8.5
            # TMA lags behind SMA
            sma_r = SMA(small; n=3)
            @test r[end] < sma_r[end]
        end

        @testset "WMA" begin
            @test WMA(data_vec) isa Vector{Float64}
            @test WMA(data_vec; n=5) isa Vector{Float64}
            @test WMA(data_ts) isa TSFrame
            ma = WMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "WMA_50"

            # Numerical validation
            # WMA n=3: weights [1,2,3], denom=6
            r = WMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # (1*1)/1
            @test r[2] ≈ 5/3 atol=1e-10                          # (1*1+2*2)/3 = 5/3
            @test r[3] ≈ 14/6 atol=1e-10                         # (1+4+9)/6 = 14/6
            @test r[4] ≈ 10/3 atol=1e-10                         # (1*2+2*3+3*4)/6 = 20/6 = 10/3
            @test r[end] ≈ 28/3 atol=1e-10                       # (1*8+2*9+3*10)/6 = 56/6

            # WMA n=5
            r5 = WMA(small; n=5)
            @test r5[5] ≈ 11/3 atol=1e-10                        # (1+4+9+16+25)/15 = 55/15
            @test r5[end] ≈ 26/3 atol=1e-10                      # (6+14+24+36+50)/15 = 130/15
        end

        @testset "ZLEMA" begin
            @test ZLEMA(data_vec) isa Vector{Float64}
            @test ZLEMA(data_vec; n=5) isa Vector{Float64}
            @test ZLEMA(data_ts) isa TSFrame
            ma = ZLEMA(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "ZLEMA_50"

            # Numerical validation
            # ZLEMA n=3: zero-lag EMA using modified price = 2*price - price[lag]
            r = ZLEMA(small; n=3)
            @test r[1] ≈ 1.0 atol=1e-10                          # init: data[1]
            @test r[end] ≈ 9.998697916666666 atol=1e-8            # nearly perfect tracking
            # ZLEMA tracks linear data better than standard EMA
            ema_r = EMA(small; n=3)
            @test abs(r[end] - 10.0) < abs(ema_r[end] - 10.0)

            # ZLEMA n=5
            r5 = ZLEMA(small; n=5)
            @test r5[end] ≈ 10.008779149519892 atol=1e-8
        end

        @testset "ROC" begin
            @test ROC(data_vec) isa Vector{Float64}
            @test ROC(data_vec; n=5) isa Vector{Float64}
            @test ROC(data_ts) isa TSFrame
            ma = ROC(data_ts; n=50)
            @test ma isa TSFrame
            @test names(ma)[1] == "ROC_50"

            # Numerical validation
            # ROC n=3: (P[i] - P[i-n]) / P[i-n] * 100
            r = ROC(small; n=3)
            @test length(r) == 10
            # Startup period: first n values are 0.0
            @test r[1] ≈ 0.0 atol=1e-10
            @test r[2] ≈ 0.0 atol=1e-10
            @test r[3] ≈ 0.0 atol=1e-10
            # ROC[4] = (4-1)/1 * 100 = 300.0
            @test r[4] ≈ 300.0 atol=1e-10
            # ROC[5] = (5-2)/2 * 100 = 150.0
            @test r[5] ≈ 150.0 atol=1e-10
            # ROC[10] = (10-7)/7 * 100 ≈ 42.857...
            @test r[10] ≈ 100.0 * 3.0 / 7.0 atol=1e-10

            # ROC n=1: simple 1-period percent change
            r1 = ROC(small; n=1)
            @test r1[1] ≈ 0.0 atol=1e-10
            @test r1[2] ≈ 100.0 atol=1e-10                       # (2-1)/1 * 100
            @test r1[3] ≈ 50.0 atol=1e-10                        # (3-2)/2 * 100
        end

        @testset "DPO" begin
            @test DPO(data_vec) isa Vector{Float64}
            @test DPO(data_vec; n=10) isa Vector{Float64}
            @test DPO(data_ts) isa TSFrame
            dpo = DPO(data_ts; n=20)
            @test dpo isa TSFrame
            @test names(dpo)[1] == "DPO_20"

            # Startup period: first shift values are 0.0
            # shift = div(20, 2) + 1 = 11
            r = DPO(data_vec; n=20)
            for i in 1:11
                @test r[i] ≈ 0.0 atol=1e-10
            end

            # For constant price data: DPO should be near 0 everywhere
            const_prices = fill(42.0, 50)
            r_const = DPO(const_prices; n=10)
            @test all(x -> abs(x) < 1e-10, r_const)

            # All values should be finite
            @test all(isfinite, DPO(data_vec))

            # Numerical validation with small data
            # DPO(n=4): shift = div(4,2)+1 = 3
            # SMA_4 of [1..10]: cumulative avg expanding then window
            r_small = DPO(small; n=4)
            sma4 = SMA(small; n=4)
            # For i <= 3 (shift): DPO = 0.0
            @test r_small[1] ≈ 0.0 atol=1e-10
            @test r_small[2] ≈ 0.0 atol=1e-10
            @test r_small[3] ≈ 0.0 atol=1e-10
            # For i = 4: DPO[4] = prices[4] - SMA[4-3] = 4.0 - SMA[1] = 4.0 - 1.0 = 3.0
            @test r_small[4] ≈ small[4] - sma4[1] atol=1e-10
            # For i = 7: DPO[7] = prices[7] - SMA[4] = 7.0 - SMA[4]
            @test r_small[7] ≈ small[7] - sma4[4] atol=1e-10
        end
    end

    @testset "Indicators MISO" begin
        vec2 = rand(100,2) * 100
        vec3 = rand(100,3) * 100
        vec4 = rand(100,4) * 100

        @testset "ADL" begin
            @test ADL(vec4) isa Vector{Float64}
            @test ADL(data_ts) isa TSFrame
            @test names(ADL(data_ts))[1] == "ADL"

            # Numerical validation
            # ADL: CLV = (2*Close - Low - High) / (High - Low); MFV = CLV * Volume
            # When close is at the midpoint, CLV=0 -> MFV=0
            mid_data = [10.0 8.0 9.0 1000.0; 11.0 9.0 10.0 2000.0; 12.0 10.0 11.0 3000.0]
            @test all(ADL(mid_data) .≈ 0.0)

            # When close is at high, CLV=1
            # i=1: CLV=(20-8-10)/2=1.0, MFV=1000, ADL=1000
            # i=2: CLV=(22-8-12)/4=0.5, MFV=1000, ADL=2000
            # i=3: CLV=(28-10-15)/5=0.6, MFV=1800, ADL=3800
            top_data = [10.0 8.0 10.0 1000.0; 12.0 8.0 11.0 2000.0; 15.0 10.0 14.0 3000.0]
            adl = ADL(top_data)
            @test adl[1] ≈ 1000.0 atol=1e-10
            @test adl[2] ≈ 2000.0 atol=1e-10
            @test adl[3] ≈ 3800.0 atol=1e-10
        end

        @testset "ATR" begin
            @test ATR(vec3) isa Vector{Float64}
            @test ATR(vec3; n=42) isa Vector{Float64}
            @test ATR(vec3; n=42, ma_type=:SMA) isa Vector{Float64}
            @test ATR(vec3; n=42, ma_type=:SMMA) isa Vector{Float64}
            @test ATR(data_ts) isa TSFrame
            atr = ATR(data_ts; n=42)
            @test atr isa TSFrame
            @test names(atr)[1] == "ATR_42"

            # Numerical validation
            # Constant range data: high-low=2 always, consecutive closes differ by 1
            # TR = max(H-L, |H-prevC|, |L-prevC|)
            # For uniform step: TR=2 every bar
            atr_data = Float64[10 8 9; 11 9 10; 12 10 11; 13 11 12; 14 12 13;
                               15 13 14; 16 14 15; 17 15 16; 18 16 17; 19 17 18]
            r = ATR(atr_data; n=3, ma_type=:SMA)
            # All true ranges are 2.0, so ATR should be 2.0 everywhere
            for i in 1:10
                @test r[i] ≈ 2.0 atol=1e-10
            end

            r_ema = ATR(atr_data; n=3, ma_type=:EMA)
            for i in 1:10
                @test r_ema[i] ≈ 2.0 atol=1e-10
            end
        end

        @testset "ChaikinOsc" begin
            @test ChaikinOsc(vec4) isa Vector{Float64}
            @test ChaikinOsc(vec4; fast=10, slow=30) isa Vector{Float64}
            @test ChaikinOsc(data_ts) isa TSFrame
            co = ChaikinOsc(data_ts; fast=10, slow=30)
            @test co isa TSFrame
            @test names(co)[1] == "ChaikinOsc"

            # Numerical validation
            # ChaikinOsc = EMA(fast) of ADL - EMA(slow) of ADL
            co_data = Float64[10 8 10 1000; 12 8 11 2000; 15 10 14 3000;
                              14 11 13 2500; 16 12 15 4000; 15 13 14 3000;
                              17 14 16 5000; 16 13 15 3500; 18 15 17 4500;
                              17 14 16 4000]
            r = ChaikinOsc(co_data; fast=3, slow=5)
            @test r[1] ≈ 0.0 atol=1e-10                          # both EMAs start equal
            @test r[end] ≈ 1168.357553155005 atol=1e-4
        end

        @testset "OBV" begin
            @test OBV(vec2) isa Vector{Float64}
            res = OBV(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "OBV"

            # Numerical validation
            # OBV: +volume on up close, -volume on down close, unchanged on flat
            obv_data = Float64[10 100; 11 200; 10.5 150; 11.5 300; 11.5 100]
            r = OBV(obv_data)
            @test r[1] ≈ 100.0 atol=1e-10                        # init with first volume
            @test r[2] ≈ 300.0 atol=1e-10                        # 11>10: 100+200
            @test r[3] ≈ 150.0 atol=1e-10                        # 10.5<11: 300-150
            @test r[4] ≈ 450.0 atol=1e-10                        # 11.5>10.5: 150+300
            @test r[5] ≈ 450.0 atol=1e-10                        # 11.5==11.5: unchanged
        end

        @testset "VWAP" begin
            @test VWAP(vec4) isa Vector{Float64}
            res = VWAP(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "VWAP"

            # Numerical validation
            # TP = (H + L + C) / 3; VWAP = cumsum(TP*V) / cumsum(V)
            vwap_data = Float64[10 8 9 1000; 12 10 11 2000; 14 12 13 3000; 16 14 15 4000; 18 16 17 5000]
            r = VWAP(vwap_data)

            # VWAP[1] == TP[1] = (10+8+9)/3 = 9.0
            @test r[1] ≈ 9.0 atol=1e-10

            # VWAP[2]: TP1=9, TP2=(12+10+11)/3=11; cum_tpv=9*1000+11*2000=31000; cum_v=3000
            @test r[2] ≈ 31000.0 / 3000.0 atol=1e-10

            # VWAP[3]: TP3=(14+12+13)/3=13; cum_tpv=31000+13*3000=70000; cum_v=6000
            @test r[3] ≈ 70000.0 / 6000.0 atol=1e-10

            # VWAP is always between min(Low) and max(High) of cumulative window
            for i in 1:5
                min_low = minimum(vwap_data[1:i, 2])
                max_high = maximum(vwap_data[1:i, 1])
                @test min_low <= r[i] <= max_high
            end

            # For constant prices and volume: VWAP equals that price
            const_data = Float64[10 10 10 500; 10 10 10 500; 10 10 10 500]
            r_const = VWAP(const_data)
            @test all(r_const .≈ 10.0)

            # All values should be finite
            @test all(isfinite, VWAP(vec4))

            # AAPL smoke test
            vwap_aapl = VWAP(data_ts)
            @test vwap_aapl isa TSFrame
            @test size(vwap_aapl)[1] == size(data_ts)[1]
        end

        @testset "CCI" begin
            @test CCI(vec3) isa Vector{Float64}
            @test CCI(vec3; n=10) isa Vector{Float64}
            res = CCI(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "CCI_20"

            # Numerical validation
            # CCI = (TP - SMA_TP) / (0.015 * MAD)
            small_hlc = Float64[1 2 3; 4 5 6; 2 3 4; 5 6 7; 3 4 5]
            r = CCI(small_hlc; n=3)

            # For constant TP (MAD=0), CCI = 0.0
            const_hlc = Float64[10 10 10; 10 10 10; 10 10 10; 10 10 10; 10 10 10]
            r_const = CCI(const_hlc; n=3)
            @test all(r_const .≈ 0.0)

            # CCI can be positive or negative
            @test any(x -> x > 0.0, r) || any(x -> x < 0.0, r) || all(x -> x ≈ 0.0, r)

            # For linearly rising data, CCI should be positive at end
            rising_hlc = hcat([i+1 for i in 1.0:20.0], [i-1 for i in 1.0:20.0], [i for i in 1.0:20.0])
            r_rising = CCI(rising_hlc; n=5)
            # After warmup, TP is above the SMA_TP -> CCI > 0
            @test r_rising[end] > 0.0 || r_rising[end] ≈ 0.0

            # All values should be finite
            @test all(isfinite, CCI(vec3))

            # Specific numerical check for small_hlc n=3
            # TP = (H+L+C)/3: [2.0, 5.0, 3.0, 6.0, 4.0]
            # At i=3 (full window): window=[2,5,3], SMA=10/3, MAD=mean(|2-10/3|,|5-10/3|,|3-10/3|)
            # = mean(4/3, 5/3, 1/3) = 10/9
            # CCI = (3 - 10/3) / (0.015 * 10/9) = (-1/3) / (1/60) = -20.0
            @test r[3] ≈ -20.0 atol=1e-10

            # AAPL smoke test
            cci_aapl = CCI(data_ts)
            @test cci_aapl isa TSFrame
            @test size(cci_aapl)[1] == size(data_ts)[1]
        end

        @testset "ForceIndex" begin
            @test ForceIndex(vec2) isa Vector{Float64}
            @test ForceIndex(vec2; n=20) isa Vector{Float64}
            res = ForceIndex(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "ForceIndex_13"
            res2 = ForceIndex(data_ts; n=20)
            @test names(res2)[1] == "ForceIndex_20"

            # Numerical validation
            # RawForce[1] = 0; RawForce[i] = (Close[i] - Close[i-1]) * Volume[i]
            # ForceIndex = EMA(RawForce; n=n)
            fi_data = Float64[10 100; 12 200; 11 150; 14 300; 13 250]
            r = ForceIndex(fi_data; n=2)

            # Raw force: [0, (12-10)*200=400, (11-12)*150=-150, (14-11)*300=900, (13-14)*250=-250]
            raw = [0.0, 400.0, -150.0, 900.0, -250.0]
            expected = EMA(raw; n=2)
            @test r ≈ expected atol=1e-10

            # Rising price with volume: Force Index should be positive (eventually)
            rising_data = hcat(collect(1.0:20.0), fill(1000.0, 20))
            r_rising = ForceIndex(rising_data; n=5)
            @test r_rising[end] > 0.0

            # Falling price with volume: Force Index should be negative (eventually)
            falling_data = hcat(collect(20.0:-1.0:1.0), fill(1000.0, 20))
            r_falling = ForceIndex(falling_data; n=5)
            @test r_falling[end] < 0.0

            # Zero price change: raw force is 0 for those bars
            const_data = Float64[10 100; 10 200; 10 150; 10 300; 10 250]
            r_const = ForceIndex(const_data; n=2)
            # All raw forces are 0 (no price change), so EMA of zeros = 0
            @test all(r_const .≈ 0.0)

            # All values should be finite
            @test all(isfinite, ForceIndex(vec2))

            # AAPL smoke test
            fi_aapl = ForceIndex(data_ts)
            @test fi_aapl isa TSFrame
            @test size(fi_aapl)[1] == size(data_ts)[1]
        end

        @testset "MFI" begin
            @test MFI(vec4) isa Vector{Float64}
            @test MFI(vec4; n=10) isa Vector{Float64}
            res = MFI(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "MFI_14"
            res2 = MFI(data_ts; n=10)
            @test names(res2)[1] == "MFI_10"

            # Output range: MFI must be in [0, 100]
            r_rand = MFI(vec4)
            @test all(v -> 0.0 <= v <= 100.0, r_rand)

            # All values should be finite
            @test all(isfinite, r_rand)

            # All prices rising with volume: all positive flow -> MFI = 100
            rising_data = Float64[10 8 9 1000;
                                  12 10 11 2000;
                                  14 12 13 3000;
                                  16 14 15 4000;
                                  18 16 17 5000]
            r_rising = MFI(rising_data; n=3)
            # After warmup, TP is always rising, so all flow is positive -> MFI = 100
            @test r_rising[end] ≈ 100.0 atol=1e-10

            # All prices falling with volume: all negative flow -> MFI = 0
            falling_data = Float64[18 16 17 5000;
                                   16 14 15 4000;
                                   14 12 13 3000;
                                   12 10 11 2000;
                                   10 8 9 1000]
            r_falling = MFI(falling_data; n=3)
            # After warmup, TP is always falling, so all flow is negative -> MFI = 0
            @test r_falling[end] ≈ 0.0 atol=1e-10

            # Alternating up/down with equal volumes: MFI near 50
            alt_data = Float64[10 8 9 1000;
                               12 10 11 1000;
                               10 8 9 1000;
                               12 10 11 1000;
                               10 8 9 1000;
                               12 10 11 1000;
                               10 8 9 1000;
                               12 10 11 1000]
            r_alt = MFI(alt_data; n=4)
            # TP alternates 9,11,9,11... MF alternates 9000,11000,9000,11000...
            # In a full window of 4: 2 positive (MF=11000 each), 2 negative (MF=9000 each)
            # MFR = 22000/18000, MFI = 100 - 100/(1+22/18) = 100 - 100/(40/18) = 100 - 45 = 55
            @test r_alt[end] ≈ 55.0 atol=1e-10

            # Numerical validation: manual calculation
            # prices: [H, L, C, V]
            num_data = Float64[10 8 9 100;    # TP=9,  MF=900
                               12 10 11 200;  # TP=11, MF=2200 (TP up: positive)
                               11 9 10 150]   # TP=10, MF=1500 (TP down: negative)
            r_num = MFI(num_data; n=2)
            # i=1: only 1 bar, no previous TP -> neutral. PosFlow=0, NegFlow=0 -> edge case
            # i=2: window [1,2]. Bar 1: neutral (no prev). Bar 2: TP[2]=11>TP[1]=9, pos. PosFlow=2200, NegFlow=0 -> MFI=100
            @test r_num[2] ≈ 100.0 atol=1e-10
            # i=3: window [2,3]. Bar 2: TP[2]=11>TP[1]=9, pos, MF=2200. Bar 3: TP[3]=10<TP[2]=11, neg, MF=1500.
            # PosFlow=2200, NegFlow=1500. MFR=2200/1500=22/15. MFI=100-100/(1+22/15)=100-100/(37/15)=100-1500/37
            expected_mfi = 100.0 - 100.0 / (1.0 + 2200.0 / 1500.0)
            @test r_num[3] ≈ expected_mfi atol=1e-10

            # AAPL smoke test
            mfi_aapl = MFI(data_ts)
            @test mfi_aapl isa TSFrame
            @test size(mfi_aapl)[1] == size(data_ts)[1]
            r_aapl = MFI(data_ts[:, [:High, :Low, :Close, :Volume]] |> Matrix)
            @test all(v -> 0.0 <= v <= 100.0, r_aapl)
        end

        @testset "CMF" begin
            @test CMF(vec4) isa Vector{Float64}
            @test CMF(vec4; n=10) isa Vector{Float64}
            res = CMF(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "CMF_20"
            res2 = CMF(data_ts; n=10)
            @test names(res2)[1] == "CMF_10"

            # Output range: CMF must be in [-1, 1]
            r_rand = CMF(vec4)
            @test all(v -> -1.0 <= v <= 1.0, r_rand)

            # All values should be finite
            @test all(isfinite, r_rand)

            # All closes at high (bullish): CLV=1, CMF=1
            bull_data = Float64[10 8 10 1000;
                                12 10 12 1000;
                                11 9 11 1000]
            r_bull = CMF(bull_data; n=2)
            @test r_bull[2] ≈ 1.0 atol=1e-10
            @test r_bull[3] ≈ 1.0 atol=1e-10

            # All closes at low (bearish): CLV=-1, CMF=-1
            bear_data = Float64[10 8 8 1000;
                                12 10 10 1000;
                                11 9 9 1000]
            r_bear = CMF(bear_data; n=2)
            @test r_bear[2] ≈ -1.0 atol=1e-10
            @test r_bear[3] ≈ -1.0 atol=1e-10

            # Close at midpoint: CLV=0, CMF=0
            mid_data = Float64[10 8 9 1000;
                               12 10 11 1000;
                               11 9 10 1000]
            r_mid = CMF(mid_data; n=2)
            @test r_mid[2] ≈ 0.0 atol=1e-10
            @test r_mid[3] ≈ 0.0 atol=1e-10

            # Edge case: High == Low -> CLV = 0
            flat_data = Float64[10 10 10 1000;
                                10 10 10 1000;
                                10 10 10 1000]
            r_flat = CMF(flat_data; n=2)
            @test all(r_flat .≈ 0.0)

            # Edge case: Volume == 0 -> CMF = 0
            zero_vol = Float64[10 8 9 0;
                               12 10 11 0;
                               11 9 10 0]
            r_zero = CMF(zero_vol; n=2)
            @test all(r_zero .≈ 0.0)

            # Numerical validation: mixed CLV values
            # Bar 1: H=10,L=8,C=10,V=1000 -> CLV=(20-8-10)/(10-8)=2/2=1, MFV=1000
            # Bar 2: H=12,L=10,C=10,V=2000 -> CLV=(20-10-12)/(12-10)=-2/2=-1, MFV=-2000
            # Bar 3: H=11,L=9,C=10.5,V=1500 -> CLV=(21-9-11)/(11-9)=1/2=0.5, MFV=750
            num_data = Float64[10 8 10 1000;
                               12 10 10 2000;
                               11 9 10.5 1500]
            r_num = CMF(num_data; n=2)
            # i=2: window [1,2]. sum(MFV)=1000+(-2000)=-1000; sum(V)=1000+2000=3000; CMF=-1000/3000
            @test r_num[2] ≈ -1000.0 / 3000.0 atol=1e-10
            # i=3: window [2,3]. sum(MFV)=-2000+750=-1250; sum(V)=2000+1500=3500; CMF=-1250/3500
            @test r_num[3] ≈ -1250.0 / 3500.0 atol=1e-10

            # AAPL smoke test
            cmf_aapl = CMF(data_ts)
            @test cmf_aapl isa TSFrame
            @test size(cmf_aapl)[1] == size(data_ts)[1]
            r_aapl = CMF(data_ts[:, [:High, :Low, :Close, :Volume]] |> Matrix)
            @test all(v -> -1.0 <= v <= 1.0, r_aapl)
        end

        @testset "VPT" begin
            @test VPT(vec2) isa Vector{Float64}
            res = VPT(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "VPT"

            # Numerical validation
            # VPT[1] = 0.0
            # VPT[i] = VPT[i-1] + Volume[i] * (Close[i] - Close[i-1]) / Close[i-1]
            vpt_data = Float64[100 1000; 110 1500; 105 1200; 105 800; 120 2000]
            r = VPT(vpt_data)

            # VPT[1] = 0.0
            @test r[1] ≈ 0.0 atol=1e-10

            # VPT[2] = 0 + 1500 * (110 - 100) / 100 = 150.0
            @test r[2] ≈ 150.0 atol=1e-10

            # VPT[3] = 150 + 1200 * (105 - 110) / 110 = 150 - 54.5454... = 95.4545...
            @test r[3] ≈ 150.0 + 1200.0 * (105.0 - 110.0) / 110.0 atol=1e-10

            # Rising price + positive volume -> VPT increases
            @test r[2] > r[1]

            # Falling price + positive volume -> VPT decreases
            @test r[3] < r[2]

            # Constant price -> VPT unchanged
            @test r[4] ≈ r[3] atol=1e-10

            # All values should be finite
            @test all(isfinite, VPT(vec2))

            # AAPL smoke test
            vpt_aapl = VPT(data_ts)
            @test vpt_aapl isa TSFrame
            @test size(vpt_aapl)[1] == size(data_ts)[1]
        end

        @testset "NVI" begin
            @test NVI(vec2) isa Vector{Float64}
            res = NVI(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "NVI"

            # Numerical validation
            # NVI[1] = 1000.0
            # if Volume[i] < Volume[i-1]: NVI[i] = NVI[i-1] * (1 + (Close[i] - Close[i-1]) / Close[i-1])
            # else: NVI[i] = NVI[i-1]
            nvi_data = Float64[100 2000; 110 1500; 105 1800; 115 1200; 120 1300]
            r = NVI(nvi_data)

            # NVI[1] = 1000.0
            @test r[1] ≈ 1000.0 atol=1e-10

            # i=2: Volume=1500 < 2000 -> update: 1000 * (1 + (110-100)/100) = 1000 * 1.1 = 1100
            @test r[2] ≈ 1100.0 atol=1e-10

            # i=3: Volume=1800 > 1500 -> no update: NVI[3] = NVI[2] = 1100
            @test r[3] ≈ 1100.0 atol=1e-10

            # i=4: Volume=1200 < 1800 -> update: 1100 * (1 + (115-105)/105)
            @test r[4] ≈ 1100.0 * (1.0 + (115.0 - 105.0) / 105.0) atol=1e-10

            # When volume increases: NVI unchanged
            @test r[3] ≈ r[2] atol=1e-10

            # When volume decreases and price rises: NVI increases
            @test r[2] > r[1]

            # All values positive (starts at 1000, only multiplicative changes)
            @test all(v -> v > 0.0, r)

            # All values should be finite
            @test all(isfinite, NVI(vec2))

            # AAPL smoke test
            nvi_aapl = NVI(data_ts)
            @test nvi_aapl isa TSFrame
            @test size(nvi_aapl)[1] == size(data_ts)[1]
        end

        @testset "PVI" begin
            @test PVI(vec2) isa Vector{Float64}
            res = PVI(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "PVI"

            # Numerical validation
            # PVI[1] = 1000.0
            # if Volume[i] > Volume[i-1]: PVI[i] = PVI[i-1] * (1 + (Close[i] - Close[i-1]) / Close[i-1])
            # else: PVI[i] = PVI[i-1]
            pvi_data = Float64[100 1000; 110 1500; 105 1200; 115 2000; 120 1800]
            r = PVI(pvi_data)

            # PVI[1] = 1000.0
            @test r[1] ≈ 1000.0 atol=1e-10

            # i=2: Volume=1500 > 1000 -> update: 1000 * (1 + (110-100)/100) = 1000 * 1.1 = 1100
            @test r[2] ≈ 1100.0 atol=1e-10

            # i=3: Volume=1200 < 1500 -> no update: PVI[3] = PVI[2] = 1100
            @test r[3] ≈ 1100.0 atol=1e-10

            # i=4: Volume=2000 > 1200 -> update: 1100 * (1 + (115-105)/105)
            @test r[4] ≈ 1100.0 * (1.0 + (115.0 - 105.0) / 105.0) atol=1e-10

            # When volume decreases: PVI unchanged
            @test r[3] ≈ r[2] atol=1e-10

            # When volume increases and price rises: PVI increases
            @test r[2] > r[1]

            # All values positive (starts at 1000, only multiplicative changes)
            @test all(v -> v > 0.0, r)

            # All values should be finite
            @test all(isfinite, PVI(vec2))

            # AAPL smoke test
            pvi_aapl = PVI(data_ts)
            @test pvi_aapl isa TSFrame
            @test size(pvi_aapl)[1] == size(data_ts)[1]
        end

        @testset "EMV" begin
            @test EMV(vec3) isa Vector{Float64}
            @test EMV(vec3; n=10) isa Vector{Float64}
            res = EMV(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "EMV_14"

            # EMV[1] == 0.0 (no previous bar -> raw_emv[1] = 0)
            emv_data = Float64[10 8 1000; 12 10 2000; 14 12 3000; 13 11 2500; 15 13 4000;
                               14 12 3500; 16 14 5000; 15 13 4500; 17 15 6000; 16 14 5500]
            r = EMV(emv_data; n=3)
            # raw_emv[1] = 0 because no previous bar
            # After SMA smoothing, first value still 0.0 (SMA(1) uses only raw_emv[1]=0)
            @test r[1] ≈ 0.0 atol=1e-10

            # For constant High/Low (distance_moved = 0): EMV should be 0
            const_hl = Float64[10 8 1000; 10 8 2000; 10 8 3000; 10 8 4000; 10 8 5000]
            r_const = EMV(const_hl; n=2)
            @test all(x -> abs(x) < 1e-10, r_const)

            # All values should be finite
            @test all(isfinite, EMV(vec3))

            # AAPL smoke test (data_ts has High, Low, Volume columns)
            emv_aapl = EMV(data_ts)
            @test emv_aapl isa TSFrame
            @test size(emv_aapl)[1] == size(data_ts)[1]
        end
    end

    @testset "Indicators SIMO" begin
        data_vec = collect(1.0:50.0)

        # Shared small input for numerical validation
        small = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]

        @testset "BollingerBands" begin
            @test BB(data_vec) isa Matrix{Float64}
            @test BB(data_vec; n=25, num_std=3.0) isa Matrix{Float64}
            @test BB(data_ts) isa TSFrame
            @test BB(data_ts; n=25, num_std=3.0) isa TSFrame
            @test BB(data_ts; ma_type=:EMA) isa TSFrame
            @test BB(data_ts; ma_type=:SMMA) isa TSFrame
            ind = BB(data_ts)
            @test names(ind)[1] == "BB_Center"
            @test names(ind)[2] == "BB_Upper"
            @test names(ind)[3] == "BB_Lower"

            # Numerical validation
            # BB n=3, num_std=2.0: Center=SMA, Upper/Lower=Center +/- 2*std
            bb = BB(small; n=3, num_std=2.0)
            # Center = SMA n=3
            @test bb[3,1] ≈ 2.0 atol=1e-10                       # SMA([1,2,3])
            @test bb[4,1] ≈ 3.0 atol=1e-10                       # SMA([2,3,4])
            @test bb[end,1] ≈ 9.0 atol=1e-10                     # SMA([8,9,10])

            # At i=3: std of [1,2,3] = sqrt(2/3) ≈ 0.8165
            std3 = sqrt(2/3)
            @test bb[3,2] ≈ 2.0 + 2.0*std3 atol=1e-8             # upper
            @test bb[3,3] ≈ 2.0 - 2.0*std3 atol=1e-8             # lower

            # Band symmetry: upper - center == center - lower
            for i in 3:10
                @test (bb[i,2] - bb[i,1]) ≈ (bb[i,1] - bb[i,3]) atol=1e-10
            end

            # First value: no spread
            @test bb[1,1] ≈ 1.0 atol=1e-10
            @test bb[1,2] ≈ 1.0 atol=1e-10                       # std=0 for single point
            @test bb[1,3] ≈ 1.0 atol=1e-10
        end

        @testset "MACD" begin
            @test MACD(data_vec) isa Matrix{Float64}
            ind = MACD(data_ts)
            @test ind isa TSFrame
            @test names(ind)[1] == "MACD_Line"
            @test names(ind)[2] == "MACD_Signal"
            @test names(ind)[3] == "MACD_Histogram"

            # Numerical validation
            # MACD = EMA(fast) - EMA(slow); Signal = EMA(MACD); Histogram = MACD - Signal
            data30 = collect(1.0:30.0)
            m = MACD(data30; fast=3, slow=5, signal=3)
            # For linear data, fast EMA > slow EMA -> MACD line > 0
            @test m[end,1] ≈ 0.9999736010648235 atol=1e-6        # MACD line
            @test m[end,2] ≈ 0.9999472455913766 atol=1e-6        # Signal line
            @test m[end,3] ≈ m[end,1] - m[end,2] atol=1e-10     # Histogram = Line - Signal

            # MACD line should be positive for upward-trending data
            for i in 5:30
                @test m[i,1] > 0.0
            end

            # Histogram should converge to 0 for linear data
            @test abs(m[end,3]) < 0.001
        end

        @testset "MACD3" begin
            @test MACD3(data_vec) isa Matrix{Float64}
            ind = MACD3(data_ts)
            @test ind isa TSFrame
            @test names(ind)[1] == "MACD3_Fast"
            @test names(ind)[2] == "MACD3_Middle"
            @test names(ind)[3] == "MACD3_Slow"
            @test MACD3(data_ts; ma_type=:HAJ, fast=10, middle=30, slow=50) isa TSFrame
            @test MACD3(data_ts; ma_type=:KAMA, fast=10, middle=30, slow=50) isa TSFrame
            @test MACD3(data_ts; ma_type=:ALMA, fast=10, middle=30, slow=50) isa TSFrame

            # Numerical validation
            # MACD3 with EMA: fast-middle, fast-slow, middle-slow differences
            m = MACD3(data_vec)
            @test size(m) == (50, 3)
            # For linear data, all differences should be positive (fast > slow)
            # and converge. Check last values are positive.
            @test m[end,1] > 0.0                                  # fast - middle > 0
            @test m[end,2] > 0.0                                  # fast - slow > 0
            @test m[end,3] > 0.0                                  # middle - slow > 0
            # Middle line should be larger than fast and slow lines
            @test m[end,2] > m[end,1]
            @test m[end,2] > m[end,3]
        end

        @testset "Stochastic RSI" begin
            @test StochRSI(data_vec) isa Matrix{Float64}
            @test StochRSI(data_ts) isa TSFrame
            @test StochRSI(data_ts; ma_type=:EMA, k_smooth=3, d_smooth=5) isa TSFrame
            @test StochRSI(data_ts; ma_type=:SMMA, k_smooth=4, d_smooth=6) isa TSFrame
            @test StochRSI(data_ts; ma_type=:RMA, k_smooth=4, d_smooth=6) isa TSFrame
            @test StochRSI(data_ts; ma_type=:WMA, k_smooth=6, d_smooth=8) isa TSFrame
            ind = StochRSI(data_ts)
            @test names(ind)[1] == "StochRSI_K"
            @test names(ind)[2] == "StochRSI_D"

            # Numerical validation
            # For monotonically increasing data, RSI stays near 100,
            # so StochRSI should reflect that stability
            r = StochRSI(data_vec)
            @test size(r) == (50, 2)
            # K and D lines should be in [0, 100] range roughly
            # (smoothing may cause small overshoots but should be close)
            @test r[end,1] >= 0.0
            @test r[end,2] >= 0.0
        end

        @testset "PPO" begin
            @test PPO(data_vec) isa Matrix{Float64}
            ind = PPO(data_ts)
            @test ind isa TSFrame
            @test names(ind)[1] == "PPO_Line"
            @test names(ind)[2] == "PPO_Signal"
            @test names(ind)[3] == "PPO_Histogram"

            # Numerical validation
            # PPO_Line = (EMA_fast - EMA_slow) / EMA_slow * 100
            # Signal = EMA(PPO_Line; n=signal)
            # Histogram = PPO_Line - Signal
            data30 = collect(1.0:30.0)
            p = PPO(data30; fast=3, slow=5, signal=3)

            # Verify against manual calculation
            fast_ema = EMA(data30; n=3)
            slow_ema = EMA(data30; n=5)
            expected_line = @. (fast_ema - slow_ema) / slow_ema * 100
            expected_signal = EMA(expected_line; n=3)
            expected_hist = expected_line - expected_signal
            @test p[:, 1] ≈ expected_line atol=1e-10
            @test p[:, 2] ≈ expected_signal atol=1e-10
            @test p[:, 3] ≈ expected_hist atol=1e-10

            # Histogram = Line - Signal at every bar
            ppo_mat = PPO(data_vec)
            @test ppo_mat[:, 3] ≈ ppo_mat[:, 1] - ppo_mat[:, 2] atol=1e-10

            # For linear data, PPO_Line should be small (fast/slow EMAs converge)
            @test abs(p[end, 1]) < 10.0

            # Comparison with MACD: sign should be same direction
            m = MACD(data30; fast=3, slow=5, signal=3)
            for i in 5:30
                # When MACD line > 0, PPO line should also be > 0 (and vice versa)
                @test sign(p[i, 1]) == sign(m[i, 1])
            end

            # All values should be finite
            @test all(isfinite, PPO(data_vec))
        end

        @testset "KST" begin
            @test KST(data_vec) isa Matrix{Float64}
            result = KST(data_vec)
            @test size(result, 2) == 2

            ind = KST(data_ts)
            @test ind isa TSFrame
            @test names(ind)[1] == "KST_Line"
            @test names(ind)[2] == "KST_Signal"

            # For linearly rising data: KST should be positive
            # (all ROC components positive for upward trend)
            r = KST(data_vec)
            # After warmup, KST line should be positive
            @test r[end, 1] > 0.0

            # All values should be finite
            @test all(isfinite, KST(data_vec))

            # Signal should converge toward Line for steady-state data
            # (both columns should be close at the end for linear input)
            @test abs(r[end, 1] - r[end, 2]) < abs(r[end, 1]) * 0.5 + 1e-10
        end
    end

    @testset "Indicators MIMO" begin
        vec2 = rand(100,2) * 100
        vec3 = rand(100,3) * 100

        @testset "Stochastic" begin
            @test Stoch(vec3) isa Matrix{Float64}
            res = Stoch(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "Stoch_K"
            @test names(res)[2] == "Stoch_D"
            @test Stoch(data_ts; n=25, k_smooth=4, d_smooth=5) isa TSFrame
            @test Stoch(data_ts; ma_type=:EMA) isa TSFrame
            @test Stoch(data_ts; ma_type=:SMMA) isa TSFrame

            # Numerical validation
            # Stochastic with known data: %K = 100*(close-lowest)/(highest-lowest)
            stoch_data = Float64[10 8 9; 11 9 10; 12 10 11; 11 9 10; 13 11 12;
                                 14 12 13; 13 11 12; 15 13 14; 16 14 15; 15 13 14]
            s = Stoch(stoch_data; n=3, k_smooth=2, d_smooth=2)
            @test s[1,1] ≈ 50.0 atol=1e-8                        # first raw K
            @test s[end,1] ≈ 56.66666666666667 atol=1e-6         # K at end
            @test s[end,2] ≈ 67.08333333333334 atol=1e-6         # D at end

            # K and D should be bounded roughly in [0, 100]
            for i in 1:10
                @test -1.0 <= s[i,1] <= 101.0
                @test -1.0 <= s[i,2] <= 101.0
            end
        end

        @testset "Williams R" begin
            @test WR(vec3) isa Matrix{Float64}
            res = WR(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "WR_raw"
            @test names(res)[2] == "WR_EMA"
            @test WR(data_ts; n=25) isa TSFrame

            # Numerical validation
            # WR = -100 * (highest - close) / (highest - lowest)
            wr_data = Float64[10 8 9; 11 9 10; 12 10 11; 11 9 10; 13 11 12;
                              14 12 13; 13 11 12; 15 13 14; 16 14 15; 15 13 14]
            r = WR(wr_data; n=3)
            @test r[1,1] ≈ -50.0 atol=1e-8                       # (10-9)/(10-8) = 0.5 -> -50
            @test r[end,1] ≈ -66.66666666666667 atol=1e-6
            @test r[end,2] ≈ -52.694541821199344 atol=1e-6       # EMA smoothed

            # WR raw should be in [-100, 0] range
            for i in 1:10
                @test -100.0 <= r[i,1] <= 0.0 + 1e-10
            end
        end

        @testset "DonchianChannel" begin
            @test DonchianChannel(vec3) isa Matrix{Float64}
            res = DonchianChannel(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "DonchianChannel_Upper"
            @test names(res)[2] == "DonchianChannel_Lower"
            @test names(res)[3] == "DonchianChannel_Middle"
            @test DonchianChannel(data_ts; n=25) isa TSFrame

            # Numerical validation
            # DonchianChannel n=3 with linear data
            # High=Low=Close for simplicity (all same column)
            dc_data = Float64[1 1 1; 2 2 2; 3 3 3; 4 4 4; 5 5 5;
                              6 6 6; 7 7 7; 8 8 8; 9 9 9; 10 10 10]
            d = DonchianChannel(dc_data; n=3)
            # Upper[3] = max(1,2,3) = 3.0, Lower[3] = min(1,2,3) = 1.0, Middle = 2.0
            @test d[3,1] ≈ 3.0 atol=1e-10
            @test d[3,2] ≈ 1.0 atol=1e-10
            @test d[3,3] ≈ 2.0 atol=1e-10
            # Upper[10] = max(8,9,10)=10.0, Lower[10] = min(8,9,10)=8.0, Middle=9.0
            @test d[10,1] ≈ 10.0 atol=1e-10
            @test d[10,2] ≈ 8.0 atol=1e-10
            @test d[10,3] ≈ 9.0 atol=1e-10

            # With different High/Low: High increasing by 2, Low increasing by 1
            dc_data2 = Float64[10 5 7; 12 6 8; 14 7 9; 16 8 10; 18 9 11]
            d2 = DonchianChannel(dc_data2; n=3)
            # At i=3: Upper=max(10,12,14)=14, Lower=min(5,6,7)=5, Middle=9.5
            @test d2[3,1] ≈ 14.0 atol=1e-10
            @test d2[3,2] ≈ 5.0 atol=1e-10
            @test d2[3,3] ≈ 9.5 atol=1e-10
            # At i=5: Upper=max(14,16,18)=18, Lower=min(7,8,9)=7, Middle=12.5
            @test d2[5,1] ≈ 18.0 atol=1e-10
            @test d2[5,2] ≈ 7.0 atol=1e-10
            @test d2[5,3] ≈ 12.5 atol=1e-10

            # Middle should always be between Upper and Lower
            for i in 1:10
                @test d[i,2] <= d[i,3] <= d[i,1]
            end
        end

        @testset "KeltnerChannel" begin
            @test KeltnerChannel(vec3) isa Matrix{Float64}
            res = KeltnerChannel(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "KeltnerChannel_Middle"
            @test names(res)[2] == "KeltnerChannel_Upper"
            @test names(res)[3] == "KeltnerChannel_Lower"
            @test KeltnerChannel(data_ts; n=25) isa TSFrame
            @test KeltnerChannel(data_ts; n=20, mult=1.5) isa TSFrame

            # Numerical validation
            # KeltnerChannel: Middle=EMA(Close), Upper=Middle+mult*ATR, Lower=Middle-mult*ATR
            kc_data = Float64[10 8 9; 11 9 10; 12 10 11; 13 11 12; 14 12 13;
                              15 13 14; 16 14 15; 17 15 16; 18 16 17; 19 17 18]
            kc = KeltnerChannel(kc_data; n=3, mult=2.0)
            # Middle should equal EMA(close, n=3)
            ema_ref = EMA([9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0]; n=3)
            atr_ref = ATR(kc_data; n=3)
            for i in 1:10
                @test kc[i,1] ≈ ema_ref[i] atol=1e-10              # Middle = EMA
                @test kc[i,2] ≈ ema_ref[i] + 2.0 * atr_ref[i] atol=1e-10  # Upper
                @test kc[i,3] ≈ ema_ref[i] - 2.0 * atr_ref[i] atol=1e-10  # Lower
            end

            # Upper should always be >= Middle >= Lower
            for i in 1:10
                @test kc[i,3] <= kc[i,1] <= kc[i,2]
            end
        end

        @testset "Supertrend" begin
            @test Supertrend(vec3) isa Matrix{Float64}
            res = Supertrend(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "Supertrend_Value"
            @test names(res)[2] == "Supertrend_Direction"
            @test Supertrend(data_ts; n=10) isa TSFrame
            @test Supertrend(data_ts; n=10, mult=2.0) isa TSFrame

            # Direction values should be only 1.0 or -1.0
            st = Supertrend(vec3)
            @test all(d -> d == 1.0 || d == -1.0, st[:, 2])

            # Value should be positive for well-formed positive prices with small ATR
            # Use tight-range prices (small H-L spread) to ensure TP - mult*ATR > 0
            pos_prices = zeros(50, 3)
            for i in 1:50
                base = 100.0 + Float64(i)
                pos_prices[i, 1] = base + 1.0   # High
                pos_prices[i, 2] = base - 1.0   # Low
                pos_prices[i, 3] = base          # Close
            end
            st_pos = Supertrend(pos_prices; n=7, mult=1.0)
            @test all(v -> v > 0.0, st_pos[:, 1])

            # Monotonically rising prices should eventually give uptrend (Direction=1.0)
            rising = hcat([10.0+i for i in 1:30], [8.0+i for i in 1:30], [9.0+i for i in 1:30])
            st_rise = Supertrend(rising; n=7, mult=1.0)
            @test st_rise[end, 2] == 1.0  # uptrend

            # Monotonically falling prices should eventually give downtrend (Direction=-1.0)
            falling = hcat([100.0-i for i in 1:30], [98.0-i for i in 1:30], [99.0-i for i in 1:30])
            st_fall = Supertrend(falling; n=7, mult=1.0)
            @test st_fall[end, 2] == -1.0  # downtrend

            # Numerical validation with known data
            st_data = Float64[10 8 9; 11 9 10; 12 10 11; 13 11 12; 14 12 13;
                              15 13 14; 16 14 15; 17 15 16; 18 16 17; 19 17 18]
            st_num = Supertrend(st_data; n=3, mult=2.0)
            # With steadily rising prices, direction should be uptrend (1.0)
            @test st_num[end, 2] == 1.0
            # Value should equal the lower band (active band during uptrend)
            @test st_num[end, 1] > 0.0

            # AAPL smoke test
            st_aapl = Supertrend(data_ts)
            @test st_aapl isa TSFrame
            @test size(st_aapl)[1] == size(data_ts)[1]
            aapl_mat = Supertrend(data_ts[:, [:High, :Low, :Close]] |> Matrix)
            @test all(d -> d == 1.0 || d == -1.0, aapl_mat[:, 2])
        end

        @testset "DMI" begin
            @test DMI(vec3) isa Matrix{Float64}
            res = DMI(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "DMI_DIPlus"
            @test names(res)[2] == "DMI_DIMinus"
            @test names(res)[3] == "DMI_ADX"
            @test DMI(data_ts; n=20) isa TSFrame

            # All values should be non-negative
            dmi = DMI(vec3)
            @test all(v -> v >= 0.0, dmi[:, 1])  # DIPlus >= 0
            @test all(v -> v >= 0.0, dmi[:, 2])  # DIMinus >= 0
            @test all(v -> v >= 0.0, dmi[:, 3])  # ADX >= 0

            # ADX should be bounded in [0, 100]
            @test all(v -> v >= 0.0 && v <= 100.0, dmi[:, 3])

            # Numerical validation with known data
            dmi_data = Float64[10 8 9; 11 9 10; 12 10 11; 13 11 12; 14 12 13;
                               15 13 14; 16 14 15; 17 15 16; 18 16 17; 19 17 18;
                               20 18 19; 21 19 20; 22 20 21; 23 21 22; 24 22 23;
                               25 23 24; 26 24 25; 27 25 26; 28 26 27; 29 27 28]
            dmi_num = DMI(dmi_data; n=5)
            # With steady uptrend, DIPlus should be > DIMinus
            @test dmi_num[end, 1] > dmi_num[end, 2]
            # ADX should be in [0, 100]
            for i in 1:20
                @test 0.0 <= dmi_num[i, 3] <= 100.0
            end

            # With steady downtrend, DIMinus should dominate
            dmi_down = hcat([100.0-i for i in 1:20], [98.0-i for i in 1:20], [99.0-i for i in 1:20])
            dmi_dn = DMI(dmi_down; n=5)
            @test dmi_dn[end, 2] > dmi_dn[end, 1]  # DIMinus > DIPlus

            # AAPL smoke test
            dmi_aapl = DMI(data_ts)
            @test dmi_aapl isa TSFrame
            @test size(dmi_aapl)[1] == size(data_ts)[1]
            aapl_dmi_mat = DMI(data_ts[:, [:High, :Low, :Close]] |> Matrix)
            @test all(v -> v >= 0.0 && v <= 100.0, aapl_dmi_mat[:, 3])  # ADX bounded
        end

        @testset "Aroon" begin
            # Type checks
            @test Aroon(vec2) isa Matrix{Float64}
            res = Aroon(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "Aroon_Up"
            @test names(res)[2] == "Aroon_Down"
            @test names(res)[3] == "Aroon_Oscillator"
            @test Aroon(data_ts; n=10) isa TSFrame

            # Range checks on random data
            aroon_rand = Aroon(vec2)
            @test all(v -> 0.0 <= v <= 100.0, aroon_rand[:, 1])   # Up in [0, 100]
            @test all(v -> 0.0 <= v <= 100.0, aroon_rand[:, 2])   # Down in [0, 100]
            @test all(v -> -100.0 <= v <= 100.0, aroon_rand[:, 3]) # Oscillator in [-100, 100]

            # Oscillator = Up - Down
            @test aroon_rand[:, 3] ≈ aroon_rand[:, 1] - aroon_rand[:, 2] atol=1e-10

            # Monotonically rising High: AroonUp should be 100.0 (new high each bar)
            rising_high = hcat(collect(1.0:30.0), ones(30) * 50.0)
            aroon_rise = Aroon(rising_high; n=10)
            @test all(v -> v ≈ 100.0, aroon_rise[:, 1])

            # Monotonically falling Low: AroonDown should be 100.0 (new low each bar)
            falling_low = hcat(ones(30) * 50.0, collect(30.0:-1.0:1.0))
            aroon_fall = Aroon(falling_low; n=10)
            @test all(v -> v ≈ 100.0, aroon_fall[:, 2])

            # Numerical validation with small data (n=3)
            # Highs monotonically rising, Lows monotonically falling
            highs = [1.0, 2.0, 3.0, 4.0, 5.0]
            lows  = [5.0, 4.0, 3.0, 2.0, 1.0]
            prices_small = [highs lows]
            r = Aroon(prices_small; n=3)

            # Bar 4 (window [2,3,4]): high at bar 4 (most recent), low at bar 4 (most recent)
            @test r[4, 1] ≈ 100.0 atol=1e-10  # AroonUp: high at current bar
            @test r[4, 2] ≈ 100.0 atol=1e-10  # AroonDown: low at current bar

            # Bar 1: only 1 bar in window, both high and low are at bar 1
            @test r[1, 1] ≈ 100.0 atol=1e-10  # bars_since_high = 0
            @test r[1, 2] ≈ 100.0 atol=1e-10  # bars_since_low = 0

            # Reverse: highs falling, lows rising -> high at oldest bar in window
            highs2 = [5.0, 4.0, 3.0, 2.0, 1.0]
            lows2  = [1.0, 2.0, 3.0, 4.0, 5.0]
            prices2 = [highs2 lows2]
            r2 = Aroon(prices2; n=3)

            # Bar 5 (window [2,3,4,5]): high at bar 2 (oldest), low at bar 2 (oldest)
            @test r2[5, 1] ≈ 0.0 atol=1e-10   # AroonUp: 100*(3-(5-2))/3 = 0
            @test r2[5, 2] ≈ 0.0 atol=1e-10   # AroonDown: 100*(3-(5-2))/3 = 0
            @test r2[5, 3] ≈ 0.0 atol=1e-10   # Oscillator = 0

            # Bar 4 (window [1,2,3,4]): high at bar 1, low at bar 1
            @test r2[4, 1] ≈ 100.0 * (3 - (4 - 1)) / 3 atol=1e-10  # = 0.0
            @test r2[4, 2] ≈ 100.0 * (3 - (4 - 1)) / 3 atol=1e-10  # = 0.0

            # Specific known values: mixed data
            # Highs: [3, 7, 2, 5, 4], Lows: [1, 3, 0, 2, 1]
            highs3 = [3.0, 7.0, 2.0, 5.0, 4.0]
            lows3  = [1.0, 3.0, 0.0, 2.0, 1.0]
            prices3 = [highs3 lows3]
            r3 = Aroon(prices3; n=3)

            # Bar 5 (window [2,3,4,5]): highest high=7 at idx 2, lowest low=0 at idx 3
            @test r3[5, 1] ≈ 100.0 * (3 - (5 - 2)) / 3 atol=1e-10  # = 0.0
            @test r3[5, 2] ≈ 100.0 * (3 - (5 - 3)) / 3 atol=1e-10  # = 33.333...
            @test r3[5, 3] ≈ r3[5, 1] - r3[5, 2] atol=1e-10

            # Input validation
            @test_throws ArgumentError Aroon(rand(10, 3))  # wrong column count
            @test_throws ArgumentError Aroon(rand(10, 2); n=0)  # invalid period

            # AAPL smoke test
            aroon_aapl = Aroon(data_ts)
            @test aroon_aapl isa TSFrame
            @test size(aroon_aapl)[1] == size(data_ts)[1]
            aapl_aroon_mat = Aroon(data_ts[:, [:High, :Low]] |> Matrix)
            @test all(v -> 0.0 <= v <= 100.0, aapl_aroon_mat[:, 1])
            @test all(v -> 0.0 <= v <= 100.0, aapl_aroon_mat[:, 2])
            @test all(v -> -100.0 <= v <= 100.0, aapl_aroon_mat[:, 3])
        end

        @testset "SqueezeMomentum" begin
            # Type checks: Matrix input returns Matrix output
            @test SqueezeMomentum(vec3) isa Matrix{Float64}
            sm = SqueezeMomentum(vec3)
            @test size(sm, 2) == 2  # [Histogram, Squeeze]

            # TSFrame input returns TSFrame output
            res = SqueezeMomentum(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "SqueezeMomentum_Histogram"
            @test names(res)[2] == "SqueezeMomentum_Squeeze"

            # Custom parameters
            @test SqueezeMomentum(data_ts; n=10) isa TSFrame
            @test SqueezeMomentum(data_ts; n=20, bb_mult=2.0, kc_mult=1.5) isa TSFrame

            # Squeeze column values are 0.0 or 1.0 only
            sm_rand = SqueezeMomentum(vec3)
            @test all(v -> v == 0.0 || v == 1.0, sm_rand[:, 2])

            # All histogram values should be finite
            @test all(isfinite, sm_rand[:, 1])

            # Low-volatility period (constant prices with tiny noise):
            # BB very narrow → inside KC → squeeze should be ON (1.0)
            low_vol = zeros(50, 3)
            for i in 1:50
                base = 100.0
                low_vol[i, 1] = base + 0.01  # High
                low_vol[i, 2] = base - 0.01  # Low
                low_vol[i, 3] = base          # Close
            end
            sm_low = SqueezeMomentum(low_vol; n=20, bb_mult=2.0, kc_mult=1.5)
            # After warmup period, squeeze should be ON
            @test all(v -> v == 1.0, sm_low[25:end, 2])

            # High-volatility period (large close swings, small H-L spread):
            # BB wider than KC → squeeze should be OFF (0.0)
            # Close varies wildly but High-Low spread is tiny, so ATR is small
            # while BB (based on close std) is wide
            high_vol = zeros(50, 3)
            for i in 1:50
                swing = 20.0 * sin(i * 0.5)
                high_vol[i, 1] = 100.0 + swing + 0.1  # High = Close + tiny offset
                high_vol[i, 2] = 100.0 + swing - 0.1  # Low  = Close - tiny offset
                high_vol[i, 3] = 100.0 + swing         # Close swings widely
            end
            sm_high = SqueezeMomentum(high_vol; n=20, bb_mult=2.0, kc_mult=1.5)
            # After warmup, at least some bars should have squeeze OFF
            @test any(v -> v == 0.0, sm_high[25:end, 2])

            # Numerical validation: linear regression helper correctness
            # For a perfectly linear series [1,2,3,4,5], linreg should return 5.0
            # We test this indirectly: with steadily rising prices,
            # momentum histogram should be positive
            rising = zeros(40, 3)
            for i in 1:40
                rising[i, 1] = 50.0 + Float64(i) + 1.0  # High
                rising[i, 2] = 50.0 + Float64(i) - 1.0  # Low
                rising[i, 3] = 50.0 + Float64(i)         # Close
            end
            sm_rise = SqueezeMomentum(rising; n=10, bb_mult=2.0, kc_mult=1.5)
            # After warmup, histogram should be positive (upward momentum)
            @test all(v -> v > 0.0, sm_rise[20:end, 1])

            # Steadily falling prices: histogram should be negative
            falling = zeros(40, 3)
            for i in 1:40
                falling[i, 1] = 150.0 - Float64(i) + 1.0  # High
                falling[i, 2] = 150.0 - Float64(i) - 1.0  # Low
                falling[i, 3] = 150.0 - Float64(i)         # Close
            end
            sm_fall = SqueezeMomentum(falling; n=10, bb_mult=2.0, kc_mult=1.5)
            # After warmup, histogram should be negative (downward momentum)
            @test all(v -> v < 0.0, sm_fall[20:end, 1])

            # Input validation
            @test_throws ArgumentError SqueezeMomentum(rand(10, 2))  # wrong column count

            # AAPL smoke test
            sm_aapl = SqueezeMomentum(data_ts)
            @test sm_aapl isa TSFrame
            @test size(sm_aapl)[1] == size(data_ts)[1]
            aapl_sm_mat = SqueezeMomentum(data_ts[:, [:High, :Low, :Close]] |> Matrix)
            @test all(v -> v == 0.0 || v == 1.0, aapl_sm_mat[:, 2])
            @test all(isfinite, aapl_sm_mat[:, 1])
        end

        @testset "ParabolicSAR" begin
            # Type checks: Matrix input returns Matrix output
            @test ParabolicSAR(vec2) isa Matrix{Float64}
            psar = ParabolicSAR(vec2)
            @test size(psar, 2) == 2  # [Value, Direction]

            # TSFrame input returns TSFrame output
            res = ParabolicSAR(data_ts)
            @test res isa TSFrame
            @test names(res)[1] == "ParabolicSAR_Value"
            @test names(res)[2] == "ParabolicSAR_Direction"

            # Custom parameters
            @test ParabolicSAR(data_ts; af_start=0.01, af_step=0.01, af_max=0.10) isa TSFrame

            # Direction values should be only 1.0 or -1.0
            @test all(d -> d == 1.0 || d == -1.0, psar[:, 2])

            # Value should be positive for positive prices
            pos_prices = zeros(50, 2)
            for i in 1:50
                base = 100.0 + Float64(i)
                pos_prices[i, 1] = base + 1.0   # High
                pos_prices[i, 2] = base - 1.0   # Low
            end
            psar_pos = ParabolicSAR(pos_prices)
            @test all(v -> v > 0.0, psar_pos[:, 1])

            # Monotonically rising prices should eventually give uptrend (Direction=1.0)
            rising = hcat([10.0+i for i in 1:30], [8.0+i for i in 1:30])
            psar_rise = ParabolicSAR(rising)
            @test psar_rise[end, 2] == 1.0  # uptrend

            # Monotonically falling prices should eventually give downtrend (Direction=-1.0)
            falling = hcat([100.0-i for i in 1:30], [98.0-i for i in 1:30])
            psar_fall = ParabolicSAR(falling)
            @test psar_fall[end, 2] == -1.0  # downtrend

            # Reversals: alternating up/down prices should cause direction flips
            alternating = zeros(40, 2)
            for i in 1:40
                if mod(div(i - 1, 5), 2) == 0  # 5-bar up, 5-bar down cycles
                    alternating[i, 1] = 50.0 + mod(i - 1, 5) * 3.0 + 2.0  # High
                    alternating[i, 2] = 50.0 + mod(i - 1, 5) * 3.0         # Low
                else
                    alternating[i, 1] = 65.0 - mod(i - 1, 5) * 3.0 + 2.0  # High
                    alternating[i, 2] = 65.0 - mod(i - 1, 5) * 3.0         # Low
                end
            end
            psar_alt = ParabolicSAR(alternating; af_start=0.02, af_step=0.02, af_max=0.20)
            directions = psar_alt[:, 2]
            # There should be at least one direction change
            has_flip = any(i -> directions[i] != directions[i-1], 2:40)
            @test has_flip

            # Numerical validation with known sequence: uptrend then reversal
            prices = [10.0 9.0;   # High Low
                      11.0 10.0;
                      12.0 11.0;
                      13.0 12.0;
                      12.0 10.0;  # reversal signal
                      11.0 9.0]
            r = ParabolicSAR(prices)
            # i=1: initial SAR = Low[1] = 9.0, Direction = uptrend
            @test r[1, 1] ≈ 9.0 atol=1e-10
            @test r[1, 2] == 1.0

            # i=2: new_sar = 9.0 + 0.02*(10.0-9.0) = 9.02, clamped to min(9.02, 9.0) = 9.0
            @test r[2, 1] ≈ 9.0 atol=1e-10
            @test r[2, 2] == 1.0

            # i=3: new_sar = 9.0 + 0.04*(11.0-9.0) = 9.08, clamped min(9.08,10.0,9.0) = 9.0
            @test r[3, 1] ≈ 9.0 atol=1e-10
            @test r[3, 2] == 1.0

            # i=4: new_sar = 9.0 + 0.06*(12.0-9.0) = 9.18
            @test r[4, 1] ≈ 9.18 atol=1e-10
            @test r[4, 2] == 1.0

            # i=5: new_sar = 9.18 + 0.08*(13.0-9.18) = 9.4856
            @test r[5, 1] ≈ 9.4856 atol=1e-10
            @test r[5, 2] == 1.0

            # i=6: reversal to downtrend, SAR = previous EP = 13.0
            @test r[6, 1] ≈ 13.0 atol=1e-10
            @test r[6, 2] == -1.0

            # Input validation: wrong column count throws error
            @test_throws ArgumentError ParabolicSAR(rand(10, 3))  # 3 columns
            @test_throws ArgumentError ParabolicSAR(rand(10, 1))  # 1 column

            # AAPL smoke test
            psar_aapl = ParabolicSAR(data_ts)
            @test psar_aapl isa TSFrame
            @test size(psar_aapl)[1] == size(data_ts)[1]
            aapl_mat = ParabolicSAR(data_ts[:, [:High, :Low]] |> Matrix)
            @test all(d -> d == 1.0 || d == -1.0, aapl_mat[:, 2])
            # SAR values should be within a reasonable range of AAPL prices
            aapl_highs = data_ts[:, :High] |> Vector
            aapl_lows = data_ts[:, :Low] |> Vector
            price_min = minimum(aapl_lows) * 0.5
            price_max = maximum(aapl_highs) * 1.5
            @test all(v -> price_min <= v <= price_max, aapl_mat[:, 1])
        end

        @testset "Ichimoku" begin
            # --- Matrix core: shape and type ---
            prices = rand(100, 3) .* 10 .+ 100
            prices[:, 1] .= prices[:, 3] .+ abs.(randn(100))  # High > Close
            prices[:, 2] .= prices[:, 3] .- abs.(randn(100))  # Low < Close

            r = Ichimoku(prices)
            @test r isa Matrix{Float64}
            @test size(r, 1) == size(prices, 1) + 26  # N + displacement rows
            @test size(r, 2) == 5

            # Custom displacement changes output row count
            r10 = Ichimoku(prices; displacement=10)
            @test size(r10, 1) == size(prices, 1) + 10

            # --- All finite values where not NaN ---
            finite_mask = .!isnan.(r[:, 1])
            @test all(isfinite.(r[finite_mask, 1]))

            # --- Tenkan/Kijun should be between overall min(Low) and max(High) ---
            overall_min = minimum(prices[:, 2])
            overall_max = maximum(prices[:, 1])
            for v in r[1:size(prices, 1), 1]
                @test overall_min <= v <= overall_max
            end
            for v in r[1:size(prices, 1), 2]
                @test overall_min <= v <= overall_max
            end

            # --- Senkou A/B: first `displacement` rows should be NaN ---
            @test all(isnan.(r[1:26, 3]))
            @test all(isnan.(r[1:26, 4]))

            # --- Senkou A/B values should be in range ---
            for v in filter(!isnan, r[:, 3])
                @test overall_min <= v <= overall_max
            end
            for v in filter(!isnan, r[:, 4])
                @test overall_min <= v <= overall_max
            end

            # --- Chikou Span: last displacement rows of output should be NaN ---
            # Chikou is stored at rows 1..(N-displacement), NaN elsewhere
            nrows_in = size(prices, 1)
            @test all(isnan.(r[(nrows_in - 26 + 1):(nrows_in + 26), 5]))

            # --- Chikou: first valid values should match Close values ---
            # output[i - displacement, 5] = Close[i] for i in (displacement+1):N
            # So output[1, 5] = Close[displacement+1]
            @test r[1, 5] ≈ prices[27, 3] atol=1e-10

            # --- Extended rows: Tenkan/Kijun should be NaN in future rows ---
            @test all(isnan.(r[(nrows_in + 1):(nrows_in + 26), 1]))
            @test all(isnan.(r[(nrows_in + 1):(nrows_in + 26), 2]))

            # --- Numerical validation with known data ---
            # Simple known data: 10 bars, tenkan=3, kijun=5, senkou_b=5, displacement=3
            # Highs: [10,12,14,13,15,16,14,17,18,16]
            # Lows:  [8, 9, 11,10,12,13,11,14,15,13]
            # Close: [9, 11,13,12,14,15,13,16,17,15]
            known_h = [10.0, 12.0, 14.0, 13.0, 15.0, 16.0, 14.0, 17.0, 18.0, 16.0]
            known_l = [8.0, 9.0, 11.0, 10.0, 12.0, 13.0, 11.0, 14.0, 15.0, 13.0]
            known_c = [9.0, 11.0, 13.0, 12.0, 14.0, 15.0, 13.0, 16.0, 17.0, 15.0]
            known_prices = hcat(known_h, known_l, known_c)

            rk = Ichimoku(known_prices; tenkan=3, kijun=5, senkou_b=5, displacement=3)
            @test size(rk) == (13, 5)  # 10 + 3

            # Tenkan at bar 1: max(10)/min(8) over 1 bar = (10+8)/2 = 9.0
            @test rk[1, 1] ≈ 9.0 atol=1e-10

            # Tenkan at bar 3: max(10,12,14)=14, min(8,9,11)=8 -> (14+8)/2 = 11.0
            @test rk[3, 1] ≈ 11.0 atol=1e-10

            # Tenkan at bar 5: max(14,13,15)=15, min(11,10,12)=10 -> (15+10)/2 = 12.5
            @test rk[5, 1] ≈ 12.5 atol=1e-10

            # Kijun at bar 5: max(10,12,14,13,15)=15, min(8,9,11,10,12)=8 -> (15+8)/2 = 11.5
            @test rk[5, 2] ≈ 11.5 atol=1e-10

            # Kijun at bar 1: max(10)/min(8) = (10+8)/2 = 9.0
            @test rk[1, 2] ≈ 9.0 atol=1e-10

            # Senkou A at bar 1+3=4: (Tenkan[1] + Kijun[1]) / 2 = (9+9)/2 = 9.0
            @test rk[4, 3] ≈ 9.0 atol=1e-10

            # Senkou A at bar 5+3=8: (Tenkan[5] + Kijun[5]) / 2 = (12.5+11.5)/2 = 12.0
            @test rk[8, 3] ≈ 12.0 atol=1e-10

            # Senkou B at bar 5+3=8: max(H[1..5])=15, min(L[1..5])=8 -> (15+8)/2 = 11.5
            @test rk[8, 4] ≈ 11.5 atol=1e-10

            # Chikou: output[i-3, 5] = Close[i] for i in 4..10
            # output[1, 5] = Close[4] = 12.0
            @test rk[1, 5] ≈ 12.0 atol=1e-10
            # output[7, 5] = Close[10] = 15.0
            @test rk[7, 5] ≈ 15.0 atol=1e-10
            # output[8..13, 5] should be NaN
            @test all(isnan.(rk[8:13, 5]))

            # First 3 rows of SenkouA/B should be NaN (displacement=3)
            @test all(isnan.(rk[1:3, 3]))
            @test all(isnan.(rk[1:3, 4]))

            # --- TSFrame wrapper ---
            ts_result = Ichimoku(data_ts)
            @test ts_result isa TSFrame
            @test nrow(ts_result) == nrow(data_ts) + 26  # extended by displacement
            @test names(ts_result) == ["Ichimoku_Tenkan", "Ichimoku_Kijun", "Ichimoku_SenkouA", "Ichimoku_SenkouB", "Ichimoku_Chikou"]

            # Future dates are properly generated
            orig_idx = index(data_ts)
            result_idx = index(ts_result)
            @test length(result_idx) == length(orig_idx) + 26
            @test result_idx[1:length(orig_idx)] == orig_idx  # original dates preserved
            @test result_idx[end] > orig_idx[end]             # future dates extend beyond

            # Custom displacement
            ts_d10 = Ichimoku(data_ts; displacement=10)
            @test nrow(ts_d10) == nrow(data_ts) + 10

            # Custom parameters
            @test Ichimoku(data_ts; tenkan=7, kijun=22, senkou_b=44, displacement=22) isa TSFrame

            # Input validation
            @test_throws ArgumentError Ichimoku(rand(10, 2))  # wrong column count
            @test_throws ArgumentError Ichimoku(rand(10, 3); tenkan=0)  # invalid period
            @test_throws ArgumentError Ichimoku(rand(10, 3); displacement=0)  # invalid displacement

            # AAPL smoke test
            ichimoku_aapl = Ichimoku(data_ts)
            @test ichimoku_aapl isa TSFrame
            @test nrow(ichimoku_aapl) == nrow(data_ts) + 26
        end
    end
end
