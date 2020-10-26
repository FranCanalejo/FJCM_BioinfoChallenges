# The classes are called, and also 'csv'
require 'csv'
require './Gene.rb'
require './SeedStock.rb'
require './HybridCross.rb'

# Each tsv file is saved in a variable. Separator is tab
# quote_char: "|" is used because of the "" of the gene_information file
# headers is false, so the header will be the first line (position 0) in each line
genes_table = CSV.read(ARGV[0], col_sep: "\t", quote_char:"|", headers: false)
seed_table = CSV.read(ARGV[1], col_sep: "\t", headers: false)
cross_table = CSV.read(ARGV[2], col_sep: "\t", headers: false)

# Empty arrays are created, so each line (except the header) of each file
# will be added as an object in the array
genes = Array.new
seeds = Array.new
crosses = Array.new

# Starting from position 1 instead of 0 the header is avoided
# Each line from position 1 is added into the empty array 'genes' as a 
# Gene class object
# As 'genes_table' stars in 0, the final position is its length minus 1
for i in 1..genes_table.length-1
    a,b,c = genes_table[i]
    genes[i] = Gene.new(:geneID => a, :name => b, :phenotype => c)
end

# Something similar is done with the seed_stock_data file
for i in 1..seed_table.length-1
    a,b,c,d,e = seed_table[i]
    # This time we use the get_gene method for the genes array
    for g in genes
        # Position 0 is nil, so a next if is added in for pass through it
        next if g==nil
        # If b(geneID from seed_stock_data file) is found into the array 'genes',
        # b value is substitute with the object, getting it from the array
        # through findinf its index
        if g.get_gene(b)
            ind = genes.find_index(g)
            b = genes[ind]
        end
    end
    # If grams are digits, they are passed to integer 
    if e =~/^\d+$/
        e = e.to_i
    end
    # Values from seed_stock_data file are added to the array 'seeds'
    # In mutant_geneID the object Gene is added as it is explained above
    seeds[i] = SeedStock.new(:seedID => a, :mutant_geneID => b, 
        :last_planted => c, :storage => d, :grams => e)
end

# In a similar way, data from cross_data file is added
for i in 1..cross_table.length-1
    a,b,c,d,e,f = cross_table[i]
    # Using the get_seed_stock method in the same way we used get_gene method above
    # so values of a and b are substituted for the objects in the array 'seeds'
    # in case they were found
    for s in seeds
        next if s==nil
        if s.get_seed_stock(a)
            ind1 = seeds.find_index(s)
            a = seeds[ind1]
        end
        if s.get_seed_stock(b)
            ind2 = seeds.find_index(s)
            b = seeds[ind2]
        end
    end
    # Values are added from 'cross_data' file
    # In parent1 and parent2 objects from array 'seeds' are added as it is
    # explained above
    crosses[i] = HybridCross.new(:parent1 => a, :parent2 => b, 
        :f2_wild => c.to_i, :f2_p1 => d.to_i, :f2_p2 => e.to_i, :f2_p1p2 => f.to_i)
end

# Method plant7g is used for each object in array 'seeds'
seeds.each do |seed|
    # Next if in case any element were nil
    next if seed == nil
    seed.plant7g
end

# Chisquare test is done for each object in array 'crosses'
crosses.each do |cross|
    # Next if in case any element were nil
    next if cross == nil
    cross.chisquare_test
end

# Final report message
puts "Final Report:"

# Any genes found to be linked are printed
genes.each do |gene|
    next if gene == nil
    if gene.linked
        puts "#{gene.name} is linked to #{gene.linked}"
    end
end

# In case this code will be run more than one time, if 'the new_stock_file.tsv'
# already exist, it is delete. That is to avoid adding each time the same lines
File.delete('new_stock_file.tsv') if File.exist?('new_stock_file.tsv')

# Each object in the array 'seeds' is written in the 'new_stock_file.tsv' database
seeds.each {|seed|
    next if seed == nil
    seed.write_database("new_stock_file.tsv")}
