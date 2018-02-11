require "vips"

module DHashVips

  module DHash
    extend self

    def hamming a, b
      (a ^ b).to_s(2).count "1"
    end

    def pixelate file, hash_size, kernel = nil
      image = Vips::Image.new_from_file file
      if kernel
        image.resize((hash_size + 1).fdiv(image.width), vscale: hash_size.fdiv(image.height), kernel: kernel).colourspace("b-w")
      else
        image.resize((hash_size + 1).fdiv(image.width), vscale: hash_size.fdiv(image.height)                ).colourspace("b-w")
      end
    end

    def calculate file, hash_size = 8, kernel = nil
      image = pixelate file, hash_size, kernel

      image.cast("int").conv([1, -1]).crop(1, 0, hash_size, hash_size).>(0)./(255).cast("uchar").to_a.join.to_i(2)
    end

  end

  module IDHash
    extend self

    def distance3 a, b
      return ((a ^ b) & (a | b) >> 128).to_s(2).count "1"
    end
    def distance a, b
      size_a, size_b = [a, b].map do |x|
        case x.size
        when            32 ; 8
        when 128, 124, 120 ; 16
        else          ; fail "invalid size of fingerprint; #{x.size}"
        end
      end
      fail "fingerprints were taken with different `power` param: #{size_a} and #{size_b}" if size_a != size_b
      ((a ^ b) & (a | b) >> 2 * size_a * size_a).to_s(2).count "1"
    end

    @@median = lambda do |array|
      h = array.size / 2
      return array[h] if array[h] != array[h - 1]
      right = array.dup
      left = right.shift h
      right.shift if right.size > left.size
      return right.first if left.last != right.first
      return right.uniq[1] if left.count(left.last) > right.count(right.first)
      left.last
    end
    fail unless 2 == @@median[[1, 2, 2, 2, 2, 2, 3]]
    fail unless 3 == @@median[[1, 2, 2, 2, 2, 3, 3]]
    fail unless 3 == @@median[[1, 1, 2, 2, 3, 3, 3]]
    fail unless 2 == @@median[[1, 1, 1, 2, 3, 3, 3]]
    fail unless 2 == @@median[[1, 1, 2, 2, 2, 2, 3]]
    fail unless 2 == @@median[[1, 2, 2, 2, 2, 3]]
    fail unless 3 == @@median[[1, 2, 2, 3, 3, 3]]
    fail unless 1 == @@median[[1, 1, 1]]
    fail unless 1 == @@median[[1, 1]]

    def fingerprint filename, power = 3
      size = 2 ** power
      image = Vips::Image.new_from_file filename
      image = image.resize(size.fdiv(image.width), vscale: size.fdiv(image.height)).colourspace("b-w")

      array = image.to_a.map &:flatten
      d1, i1, d2, i2 = [array, array.transpose].flat_map do |a|
        d = a.zip(a.rotate(1)).flat_map{ |r1, r2| r1.zip(r2).map{ |i,j| i - j } }
        m = @@median.call d.map(&:abs).sort
        [
          d.map{ |c| c     <  0 ? 1 : 0 }.join.to_i(2),
          d.map{ |c| c.abs >= m ? 1 : 0 }.join.to_i(2),
        ]
      end
      (((((i1 << size * size) + i2) << size * size) + d1) << size * size) + d2
    end

  end

end
