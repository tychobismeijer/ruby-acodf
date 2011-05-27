require 'narray'
require 'cairo'

class AcoDF
    attr_accessor :npoints

    def initialize(points)
        @npoints = points.length
        @points = points;
        @pheremone = NArray.float(@npoints, @npoints).fill!(0.0);
        for n1 in 1...@npoints do
            for n2 in 0...(n1) do
                @pheremone[n1, n2] = rand()
            end
        end
        @delta_pheremone = NArray.float(@npoints, @npoints).fill!(0.0)
    end

    def dist(x, y)
        # TODO implement precomputed distances
        sumsq = 0
        for i in (0...(@points[x].length)) do
            sumsq += (@points[x][i] - @points[y][i])**2
        end
        ans = Math.sqrt(sumsq)
        return ans
    end

    def pheremone(x, y)
        if (x < y) then
            x, y = y, x
        end
        @pheremone[x,y]
    end

    def debug_pheremone()
        print("Showing pheremone data. size = ", @npoints, "\n")
        print(@pheremone.to_a, "\n");
    end

    def inc_pheremone(x, y, q)
        if (x < y) then
            x, y = y, x
        end
        @delta_pheremone[x,y] += q
    end

    def update_pheremone
        decay_speed = 0.8
        @pheremone = (@pheremone * decay_speed) + @delta_pheremone
        @delta_pheremone.fill!(0.0)
    end

    def graph (filename)
        h_max = 16
        h_min = -6
        w_max = 16
        w_min = -6

        surface = Cairo::PDFSurface.new(filename,(w_min.abs+w_max.abs)*100,(h_min.abs+h_max.abs)*100)
        cr = Cairo::Context.new(surface)
        for p in @points do
            draw_point(cr, (p[0]-w_min)*100, (p[1]-w_min)*100)
        end
        total_pheremone = 0
        t = 0
        for n1 in 1...@npoints do
            for n2 in 0...(n1) do
                total_pheremone += @pheremone[n1, n2]
                t+=1
            end
        end
        mean_pheremone = total_pheremone/t
        print("Mean pheremone = ", mean_pheremone, "\n");
        for n1 in 1...@npoints do
            for n2 in 0...(n1) do
                p1 = @points[n1]
                p2 = @points[n2]
                if (@pheremone[n1, n2] > mean_pheremone) then
                    draw_line(cr,
                        (p1[0]-w_min)*100, (p1[1]-h_min)*100,
                        (p2[0]-w_min)*100, (p2[1]-h_min)*100,
                        1)
                end
            end
        end
    end
    
  private
    
    def draw_point(cr, x, y)
        cr.set_source_rgba(0, 0, 0, 1)
        cr.arc(x, y, 0.5, 0, 2*Math::PI)
        cr.set_line_width(0)
        cr.fill
    end

    def draw_line(cr, x1, y1, x2, y2, shade)
        # if (shade < 0.1) then return; end
        cr.set_source_rgba(0, 0, 0, shade)
        cr.set_line_cap(Cairo::LINE_CAP_ROUND)
        cr.move_to(x1, y1)
        cr.line_to(x2, y2)
        cr.set_line_width(1)
        cr.stroke
    end
end

class Ant
    def initialize(field)
        @field = field;
        reset()
    end

    def reset()
        @walk = []
    end

    def walk(length, ignore_pheremone=false)
        first_step()
        (length-1).times { step(ignore_pheremone) }
    end

    def drop_pheremone()
        pheremone_quantity = 10000
        walk_length = 0
        for i in (0...(@walk.length)-1) do
            walk_length += @field.dist(@walk[i], @walk[i+1]);
        end
        #  print(" ", walk_length, "\n");
        for i in (0...(@walk.length)-1) do
            @field.inc_pheremone(@walk[i], @walk[i+1], pheremone_quantity/(walk_length))
        end
    end

    def debug()
        debug_walk()
    end

    def debug_walk()
        print("Walk list: ", @walk, "\n")
    end

  private
    
    def first_step()
        @walk.push(rand@field.npoints)
    end

    def step(ignore_pheremone)
        if ignore_pheremone then
            @walk.push(select_city_random());
        else
            @walk.push(select_city_pheremone());
        end
    end

    def select_city_pheremone()
        raise "No cities left to select from" if (@walk.length >= @field.npoints) 
        n_cities = 10
        cities = []
        for i in 0...n_cities
            begin
                city = rand(@field.npoints)
            end while (@walk.index(city) != nil)
            cities.push(city)
        end
        cities.sort! {|x,y|
            @field.pheremone(y, @walk.last) <=>
            @field.pheremone(x, @walk.last)
            #@field.dist(x, @walk.last) <=>
            #@field.dist(y, @walk.last)
        }

        return cities[0]
    end

    def select_city_random()
        raise "No cities left to select from" if (@walk.length >= @field.npoints) 
        n_cities = 10
        cities = []
        for i in 0...n_cities
            begin
                city = rand(@field.npoints)
            end while (@walk.index(city) != nil)
            cities.push(city)
        end
        cities.sort! {|x,y|
            #@field.pheremone(y, @walk.last) <=>
            #@field.pheremone(x, @walk.last)
            @field.dist(x, @walk.last) <=>
            @field.dist(y, @walk.last)
        }

        return cities[0]
=begin
        raise "No cities left to select from" if (@walk.length >= @field.npoints) 
        begin
            city = rand(@field.npoints)
        end while (@walk.index(city) != nil)
        # print "r"
        return city
    end
=end
    end
end
# Modification from function by PLEAC project
# http://pleac.sourceforge.net/pleac_ruby/numbers.html
# 26 May 2011
def gaussian_rand
    begin
        u1 = 2 * rand() - 1
        u2 = 2 * rand() - 1
        w = u1*u1 + u2*u2
    end while (w >= 1)
    w = Math.sqrt((-2*Math.log(w))/w)
    u1*w
end


def generate_square(mudiff, sigma, clustersize)
    data = []
    for cx in 0..1 do
        for cy in 0..1 do
            for i in 0..clustersize
                data.push([
                    (cx*mudiff)+gaussian_rand()*sigma,
                    (cy*mudiff)+gaussian_rand()*sigma
                ])
            end
        end
    end
    return data
end



#data = [[10 , 20],
#        [4 , 2],
#        [33 , 50],
#        [33 , 11],
#        [44 , 23],
#        [53 , 22],
#        [75 , 90]]
data = generate_square(10, 2, 250)

f = AcoDF.new(data);
a = Ant.new(f);
cities_to_visit = 200
cooling_rate = 0.995
n_ants = 10
#f.graph("before.pdf")
begin
    print(cities_to_visit.ceil, " ")
    #T_0
    n_ants.times {
        a.walk(cities_to_visit.ceil, ignore_pheremone=true)
        a.drop_pheremone()
        a.reset()
    }
    f.update_pheremone()
    #T_1_1
    n_ants.times {
        a.walk((((2*cities_to_visit)/3)-(cities_to_visit/6)).ceil)
        #a.walk(cities_to_visit.ceil)
        a.drop_pheremone()
        a.reset()
    }
    f.update_pheremone()
    #T_1_2
    n_ants.times {
        a.walk((((2*cities_to_visit)/3)-((2*cities_to_visit)/6)).ceil)
        #a.walk(cities_to_visit.ceil)
        a.drop_pheremone()
        a.reset()
    }
    f.update_pheremone()
    
    cities_to_visit = cities_to_visit * cooling_rate;
end while (cities_to_visit > 50)
f.graph("after.pdf")
