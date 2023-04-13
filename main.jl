using GLMakie

w = 154.94
h = 87.16

function update_point!(point, io)
    linex = readline(io)
    liney = readline(io)

    mx = match(r"Event: time \d+\.?\d*, type 3 \(EV_ABS\), code 53 \(ABS_MT_POSITION_X\), value (\d+)", linex)
    isnothing(mx) && return nothing

    my = match(r"Event: time \d+\.?\d*, type 3 \(EV_ABS\), code 54 \(ABS_MT_POSITION_Y\), value (\d+)", liney)
    isnothing(my) && return nothing

    x = w*parse(Int, only(mx.captures))/(2^15 - 1)
    y = h*parse(Int, only(my.captures))/(2^15 - 1)
    
    point[] = Point2f(x, y)

    return nothing
end

io = open(`sudo evtest --grab /dev/input/event21`)

point = Observable{Point2f}()
points = Observable(Point2f[])
on(point) do xy
    push!(points[], xy)
    notify(points)
end

f = Figure()
ax = Axis(f[1, 1], aspect = DataAspect(), limits = ((0, w), (0, h)), xlabel = "X (cm)", ylabel = "Y (cm)")
lines!(ax, points)

p = @async while isopen(io)
    update_point!(point, io)
    yield()
end








































































































function update_points!(pointss, io)
    line = readline(io)
    m = match(r"Event: time \d+.\d+, type 3 \(EV_ABS\), code 47 \(ABS_MT_SLOT\), value (\d+)", line)
    isnothing(m) && return nothing
    i = parse(Int, only(m.captures)) + 1

    line = readline(io)
    m = match(r"Event: time \d+\.?\d*, type 3 \(EV_ABS\), code 53 \(ABS_MT_POSITION_X\), value (\d+)", line)
    isnothing(m) && return nothing
    x = parse(Int, only(m.captures))

    line = readline(io)
    m = match(r"Event: time \d+\.?\d*, type 3 \(EV_ABS\), code 54 \(ABS_MT_POSITION_Y\), value (\d+)", line)
    isnothing(m) && return nothing
    y = parse(Int, only(m.captures))
    
    push!(pointss[i][], Point2f(x, y))
    notify(pointss[i])

    return nothing
end

pointss = [Observable(Point2f[]) for _ in 1:10]
f = Figure()
ax = Axis(f[1, 1], aspect = DataAspect(), limits = ((0, 2^15 - 1), (0, 2^15 - 1)))
for (i, points) in enumerate(pointss)
    lines!(ax, points)
end

io = open(`sudo evtest --grab /dev/input/event21`)

p = @async while isopen(io)
    update_points!(pointss, io)
end

map(x -> empty!(x[]), pointss)



function update_point!(point, line)
    m = match(r"Event: time \d+\.?\d*, type 2 \(EV_ABS\), code \d \(ABS_(X|Y)\), value (\d+)", line)
    if !isnothing(m)
        d, _v = m.captures
        v = parse(Int, _v)
        point[d] = v
    end
end

function get_point(io)
    point = Dict("X" => -1, "Y" => -1)
    for line in eachline(io)
        update_point!(point, line)
        if point["X"] ≠ -1 && point["Y"] ≠ -1
            return point
        end
    end
end

io = open(`sudo evtest --grab /dev/input/event21`)

points = Observable(Point2f[])
p = @async while isopen(io)
    point = get_point(io)
    push!(points[], Point2f(point["X"], point["Y"]))
    notify(points)
    # sleep(0.1)
end

f = Figure()
ax = Axis(f[1, 1], aspect = DataAspect(), limits = ((0, 2^15 - 1), (0, 2^15 - 1)))
scatter!(ax, points)


# get_point(io)
#
# for line in eachline(io)
#     println(line)
# end
