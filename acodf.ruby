require 'narray'
require 'nimage'
require 'cairo'

class AcoDF
    attr_accessor :npoints

    def initialize(points)
        @npoints = points.length
        @points = points;
        @pheremone = NArray.float(@npoints, @npoints).random!;
        #@pheremone = NArray.float(@npoints, @npoints)
    end

    def dist(x, y)
        # TODO implement precomputed distances
        sumsq = 0
        for i in (0...(@points[x].length)) do
            sumsq = (@points[x][i] - @points[y][i])**2
        end
        Math.sqrt(sumsq)
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
        #win = NImage.show @pheremone
        #print "Hit return key..."
        #STDIN.getc
        #win.close
    end

    def inc_pheremone(x, y, q)
        if (x < y) then
            x, y = y, x
        end
        @pheremone[x,y] += q
    end

    def decay()
        decay_speed = 0.9
        @pheremone = @pheremone*decay_speed
    end

    def graph (filename)
        h = 100
        w = 100
        lw = 17
        surface = Cairo::PDFSurface.new(filename, w,h)
        cr = Cairo::Context.new(surface)
        for p in @points do
            draw_point(cr, p[0], p[1])
        end
        for n1 in 1...@npoints
            for n2 in 0...(n1) do
                p1 = @points[n1]
                p2 = @points[n2]
                draw_line(cr, p1[0], p1[1], p2[0], p2[1], @pheremone[n1, n2])
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

    def walk(length)
        first_step()
        (length-1).times { step() }
    end

    def drop_pheremone()
        pheremone_quantity = 1;
        walk_length = 0
        for i in (0...(@walk.length)-1) do
            walk_length += @field.dist(@walk[i], @walk[i+1]);
        end
        for i in (0...(@walk.length)-1) do
            @field.inc_pheremone(@walk[i], @walk[i+1], pheremone_quantity/walk_length)
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

    def step()
        @walk.push(select_city);
    end

    def select_city()
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
            @field.dist(x, @walk.last)*@field.pheremone(x, @walk.last) <=>
            @field.dist(y, @walk.last)*@field.pheremone(y, @walk.last)
        }
        cities[0]
    end
end

data = [[10 , 20],
        [4 , 2],
        [33 , 50],
        [33 , 11],
        [44 , 23],
        [53 , 22],
        [75 , 90]]

f = AcoDF.new(data);
f.graph("before.pdf")
a = Ant.new(f);
1000.times {
    10.times {
        a.walk(3)
        a.drop_pheremone()
        a.reset()
    }
    f.decay()
}
f.graph("after.pdf")
