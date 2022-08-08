using SimpleCompression
using Test

begin
    for (engine, type) in [(SimpleCompression.Simple64(), UInt64), (SimpleCompression.Simple32(), UInt32)]
        max_bits = 8 * sizeof(type) - 4
        @show engine type max_bits

        for n in 1:max_bits
            mask = (1 << n) - 1
            compressed = Vector{type}()
            data = mask .& rand(type, 100)
            for v in data
                SimpleCompression.add!(engine, v) do w
                    push!(compressed, w)
                end
            end
            SimpleCompression.flush!(engine) do w
                push!(compressed, w)
            end
            @test length(compressed) ≤ length(data) - (n < max_bits÷2) + 1

            uncompressed = SimpleCompression.uncompress!([], compressed)
            @test all(uncompressed[1:length(data)] .== data)
            @test all(uncompressed[(length(data)+1):end] .== 0)
        end
    end
end

begin
    for (engine, type) in [(SimpleCompression.Simple64(), UInt64), (SimpleCompression.Simple32(), UInt32)]
        max_bits = 8 * sizeof(type) - 4
        mask = (1 << max_bits) - 1
        @show engine type max_bits

        for n in 1:max_bits
            # this data is about 99% less than 2^n. That means we
            # see long runs less than that which tests that the compressor
            # doesn't get fooled by mostly small, but sometimes big values
            data = mask .& type.(floor.(-0.2 * 2.0^n * log.(rand(30000))))

            # round trip
            compressed = SimpleCompression.compress!(Vector{type}(), data)
            uncompressed = SimpleCompression.uncompress!([], compressed)

            # all the same (but for some zero padding?)
            @test all(uncompressed[1:length(data)] .== data)
            @test all(uncompressed[(length(data)+1):end] .== 0)
        end
    end
end


