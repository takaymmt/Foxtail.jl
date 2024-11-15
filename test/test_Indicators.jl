@testset "Indicators SISO" begin
    data_vec = collect(1.0:30.0)
    aapl = CSV.read(joinpath(dirname(@__FILE__), "aapl.csv"), TSFrame)
    data_ts = aapl[end-100:end]

    @testset "ALMA" begin
        @test ALMA(data_vec) isa Vector{Float64}
        @test ALMA(data_vec; n=5) isa Vector{Float64}
        @test ALMA(data_ts) isa TSFrame
        ma = ALMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "ALMA_50"
        @test ALMA(data_ts; offset=0.9, sigma=5.5, n=20) isa TSFrame
    end

    @testset "EMA" begin
        @test EMA(data_vec) isa Vector{Float64}
        @test EMA(data_vec; n=5) isa Vector{Float64}
        @test EMA(data_ts) isa TSFrame
        ma = EMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "EMA_50"
    end

    @testset "DEMA" begin
        @test DEMA(data_vec) isa Vector{Float64}
        @test DEMA(data_vec; n=5) isa Vector{Float64}
        @test DEMA(data_ts) isa TSFrame
        ma = DEMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "DEMA_50"
    end

    @testset "HMA" begin
        @test HMA(data_vec) isa Vector{Float64}
        @test HMA(data_vec; n=5) isa Vector{Float64}
        @test HMA(data_ts) isa TSFrame
        ma = HMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "HMA_50"
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
    end

    @testset "KAMA" begin
        @test KAMA(data_vec) isa Vector{Float64}
        @test KAMA(data_vec; n=5) isa Vector{Float64}
        @test KAMA(data_ts) isa TSFrame
        ma = KAMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "KAMA_50"
        @test KAMA(data_ts; fast=5, slow=25, n=15) isa TSFrame
    end

    @testset "RSI" begin
        @test RSI(data_vec) isa Vector{Float64}
        @test RSI(data_vec; n=5) isa Vector{Float64}
        @test RSI(data_ts) isa TSFrame
        ma = RSI(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "RSI_50"
        @test RMA(data_ts; n=25) isa TSFrame
    end

    @testset "SMA" begin
        @test SMA(data_vec) isa Vector{Float64}
        @test SMA(data_vec; n=5) isa Vector{Float64}
        @test SMA(data_ts) isa TSFrame
        ma = SMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "SMA_50"
        @test RMA(data_ts; n=25) isa TSFrame
    end

    @testset "SMMA" begin
        @test SMMA(data_vec) isa Vector{Float64}
        @test SMMA(data_vec; n=5) isa Vector{Float64}
        @test SMMA(data_ts) isa TSFrame
        ma = SMMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "SMMA_50"
    end

    @testset "T3" begin
        @test T3(data_vec) isa Vector{Float64}
        @test T3(data_vec; n=5) isa Vector{Float64}
        @test T3(data_ts) isa TSFrame
        ma = T3(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "T3_50"
        @test T3(data_ts;n=25, a=0.6) isa TSFrame
    end

    @testset "TEMA" begin
        @test TEMA(data_vec) isa Vector{Float64}
        @test TEMA(data_vec; n=5) isa Vector{Float64}
        @test TEMA(data_ts) isa TSFrame
        ma = TEMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "TEMA_50"
    end

    @testset "TMA" begin
        @test TMA(data_vec) isa Vector{Float64}
        @test TMA(data_vec; n=5) isa Vector{Float64}
        @test TMA(data_ts) isa TSFrame
        ma = TMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "TMA_50"
        @test TRIMA(data_ts; n=25) isa TSFrame
    end

    @testset "WMA" begin
        @test WMA(data_vec) isa Vector{Float64}
        @test WMA(data_vec; n=5) isa Vector{Float64}
        @test WMA(data_ts) isa TSFrame
        ma = WMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "WMA_50"
    end

    @testset "ZLEMA" begin
        @test ZLEMA(data_vec) isa Vector{Float64}
        @test ZLEMA(data_vec; n=5) isa Vector{Float64}
        @test ZLEMA(data_ts) isa TSFrame
        ma = ZLEMA(data_ts; n=50)
        @test ma isa TSFrame
        @test names(ma)[1] == "ZLEMA_50"
    end
end

@testset "Indicators MISO" begin
    vec3 = rand(100,3) * 100
    vec4 = rand(100,4) * 100
    aapl = CSV.read(joinpath(dirname(@__FILE__), "aapl.csv"), TSFrame)
    data_ts = aapl[end-100:end]

    @testset "ADL" begin
        @test ADL(vec4) isa Vector{Float64}
        @test ADL(data_ts) isa TSFrame
        @test names(ADL(data_ts))[1] == "ADL"
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
    end

    @testset "ChaikinOsc" begin
        @test ChaikinOsc(vec4) isa Vector{Float64}
        @test ChaikinOsc(vec4; fast=10, slow=30) isa Vector{Float64}
        @test ChaikinOsc(data_ts) isa TSFrame
        co = ChaikinOsc(data_ts; fast=10, slow=30)
        @test co isa TSFrame
        @test names(co)[1] == "ChaikinOsc"
    end
end
