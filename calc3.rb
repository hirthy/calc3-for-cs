#!/usr/bin/env ruby1.9

require 'mathn'

class Vector
  def find_householder_reflection
    orig = self
    a = orig.to_a
    if a[0].is_a?(Array)
      a = a[0]
    end

    a[0] = a[0] + sign(a[0]) * self.r

    u = Vector[*a]
    norm_u_sqrd = u.r**2
    uut = u.covector.transpose * u.covector
    h = Matrix.identity(uut.row_size) - (uut * (2 / norm_u_sqrd))
    return h
  end

  private
  def sign(x)
    return 1 if x > 0
    return -1 if x < 0
    return 0
  end
end

class Matrix
  #
  # Performs a Householder reflection for self.
  #
  def householder
    return nil unless self.square?
    current_iteration = self
    init_dim = self.row_size
    h_list = []
    cv = current_iteration.column_vectors[0]
    h = (cv.find_householder_reflection - Matrix.identity(cv.size)).expand_to_dimensions(init_dim,init_dim) + Matrix.identity(init_dim)
    h_list << h
    current_iteration = h * current_iteration
    for i in 0..(self.row_size - 1)
      cv = current_iteration.get_column_vector(i+1)
      if cv.size < 2
        break
      end
      h = (cv.find_householder_reflection - Matrix.identity(cv.size)).expand_to_dimensions(init_dim,init_dim) + Matrix.identity(init_dim)
      h_list << h
      current_iteration = h * current_iteration
    end
    q = h_list.inject(&:*)
    r = current_iteration
    return q,r
  end
  #
  # Expands a matrix to x,y
  #
  def expand_to_dimensions(x,y)
    curr_x = self.row_size
    curr_y = self.column_size
    a = self.to_a
    a.each_index do |row|
      for i in 0..(y - curr_y - 1)
        a[row] = a[row].insert(0,0)
      end
    end
    for i in 0..(x - curr_x - 1)
      a = a.insert(0,Array.new(y){0})
    end
    return Matrix.rows(a)
  end
  #
  # Finds a shorter cv
  #
  def get_column_vector(x)
    return Vector.elements(self.column(x)[x..-1])
  end
  #
  # Prints out the Matrix in a nice format
  #
  def pretty_print
    str = ""
    self.to_a.each do |row|
      row.each do |i|
        if i.to_i >= 0
          str << " "
        end
        if ("%.3f" % i).to_f == i.to_i
          str << "#{i.to_i}     "
        else
          str << "%.3f " % i
        end
      end
      str << "\n"
    end
    puts str
  end
  #
  # Determines whether or not a matrix is lower triangular, where all values above
  # the diagonal are 0.
  #
  def is_lower_triangular?
    triangular(self.column_vectors)
  end
  #
  # Determines whether or not a matrix is upper triangular, where all values below
  # the diagonal are 0.
  #
  def is_upper_triangular?
    triangular(self.row_vectors)
  end
  #
  # Creates an +n+ by +n+ Hilbert matrix.
  #
  def self.hilbert(n)
    m = Matrix.zero(n).to_a
    m = m.each_index.map{|row| m[row].each_index.map{|col| 1 / (row + col + 1)}}
    return Matrix.rows(m)
  end

  private
  def triangular(vecs)
    for i in 0..(vecs.length - 1)
      vec = vecs[i].to_a
      unless i <= 1
        return false unless vec[0..(i-1)].all? { |n| n == 0 }
      end
    end
    return true
  end
end

def solve_hilbert(size)
  h = Matrix.hilbert(size)
  q,r = h.householder
  b = Vector.elements(Array.new(size){1})
  x = r.inverse * q.inverse * b.covector.transpose
  err1 = ((q * r) - h).to_a.map{|ar|ar.map{|arr|arr.abs}.inject(&:+)}.sort[0]
  err2 = ((h * x) - b).column(0).r
  return x, err1, err2
end

for i in 2..20
  puts "N = #{i}"
  sol,err1,err2 = solve_hilbert(i)
  sol.pretty_print
  puts "err1 = #{err1}"
  puts "err2 = #{err2}"
  puts "\n"
end