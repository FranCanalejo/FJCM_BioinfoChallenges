# Classes required
require 'net/http'
require 'bio'
require 'bio/db/embl/embl'

# Load into an array the list of genes from file
gene_list=[]
File.open("ArabidopsisSubNetwork_GeneList.txt").each do |line|
    line.strip!
    gene_list.append(line)
end


genes_embl = Hash.new # Empty hash for saving embl objects
target = Bio::Sequence::NA.new('CTTCTT') # Target region we are looking for as sequence object
gene_list.each do |gene|
    address = URI("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{gene}")
    response = Net::HTTP.get_response(address) 
    record = response.body
    datafile = Bio::EMBL.new(record) # Generate embl object from the information of emsemble

    match_gene = Regexp.new(gene, Regexp::IGNORECASE) # Match to make sure we get the correct exons
    datafile.features.each do |feature|
        next unless feature.feature == "exon" && feature.assoc.values.join(',').match(match_gene) # We only get exons from our gene
        case feature.position
        when /^(\d+)\.\.(\d+)/ # When the exon is in the forward strand
            re = Regexp.new(target.to_re, Regexp::IGNORECASE)
            exon_begins = $1.to_i
            exon_ends = $2.to_i
            pos = datafile.seq.subseq(exon_begins, exon_ends).enum_for(:scan, re).map {Regexp.last_match.begin(0)} # To scan for the target region and save coordinates
            pos.each do |x|
                # Each region found is saved as a new feature
                t = Bio::Feature.new('region', "#{x+exon_begins}..#{x+exon_begins+target.length-1}")
                t.append(Bio::Feature::Qualifier.new("repeat_motif", "#{target.to_s.upcase}"))
                # Information from the exon is also annotated in the new feature
                feature.assoc.each do |key, value|
                    t.append(Bio::Feature::Qualifier.new("#{key}", "#{value}"))
                end
                datafile.features << t
            end
        when /^complement\((\d+)\.\.(\d+)\)/ # When the exon is in the reverse strand
            re = Regexp.new(target.complement.to_re, Regexp::IGNORECASE) # Target region to look for is the reverse complement of CTTCTT
            # Same as before
            exon_begins = $1.to_i
            exon_ends = $2.to_i
            pos = datafile.seq.subseq(exon_begins, exon_ends).enum_for(:scan, re).map {Regexp.last_match.begin(0)}
            pos.each do |x|
                t = Bio::Feature.new('region', "complement(#{x+exon_begins}..#{x+exon_begins+target.length-1})")
                t.append(Bio::Feature::Qualifier.new("repeat_motif", "#{target.to_s.upcase}"))
                feature.assoc.each do |key, value|
                    t.append(Bio::Feature::Qualifier.new("#{key}", "#{value}"))
                end
                datafile.features << t
            end
        end
    end
    genes_embl[gene] = datafile # The embl object is saved if a hash
    puts("#{gene}: CTTCTT repeats in exons added as features")
end

puts "Generating GFF file with CTTCTT repeats in exons..."
gff = "" # Empty string to add information for GFF3 file
gene_list.each do |gene|
    genes_embl[gene].features.each do |feature|
        # Only information from the repeat motif CTTCTT si saved in the GFF3 file
        next unless feature.feature == "region" && feature.assoc["repeat_motif"] == "CTTCTT"
        case feature.position
        when /^(\d+)\.\.(\d+)/ # When the repeat is in the forward strand
            begins = $1.to_i
            ends = $2.to_i
            gff += "#{gene}\tAssigment3\t#{feature.feature}\t#{begins}\t#{ends}\t.\t+\t.\trepeat_motif=#{feature.assoc["repeat_motif"]};#{feature.assoc["note"]}\n"
        when /^complement\((\d+)\.\.(\d+)\)/ # When the repeat is in the reverse strand
            begins = $1.to_i
            ends = $2.to_i
            gff += "#{gene}\tAssigment3\t#{feature.feature}\t#{begins}\t#{ends}\t.\t-\t.\trepeat_motif=#{feature.assoc["repeat_motif"]};#{feature.assoc["note"]}\n"
        end
    end
end

record = Bio::GFF::GFF3.new(gff) unless gff.nil?
# The GFF3 file is generated from the gff object
gff_file = File.open("CTTCTT_exons.gff3", "w")
gff_file.write("#{record.to_s}")
gff_file.close
puts "GFF3 file generated"

genes_with_target = [] # Empty array to get genes from the gff file
record.records.each do |feature|
    gene = feature.seqid
    genes_with_target.append(gene) unless genes_with_target.include?(gene) # Genes with the CTTCTT repeat are saved in the array
end

file = File.open("report.txt", "w")
genes_without_target = gene_list-genes_with_target # Genes from the list without the CTTCTT repeat are saved in a new array
puts "List of genes that do not have exons with the CTTCTT repeat motif: #{genes_without_target}"
# A report which shows the genes without the CTTCTT repeat is generated
file.write("List of genes that do not have exons with the CTTCTT repeat motif:\n#{genes_without_target}")
file.close
puts "Report generated"

# The GFF generator code from above with some changes to get coordinates of the CTTCTT repeats in the chromosomes
puts "Generating GFF file with CTTCTT repeats in chromosomes..."
gff = ""
gene_list.each do |gene|
    # The chromosome number and the beginning of the gene are obtained from the definition
    if genes_embl[gene].definition =~ /chromosome\s(\d+).+sequence\s(\d+)\.\.\d+/
        chr_number = $1.to_i
        chr_begin = $2.to_i
        genes_embl[gene].features.each do |feature|
            next unless feature.feature == "region" && feature.assoc["repeat_motif"] == "CTTCTT"
            case feature.position
            when /^(\d+)\.\.(\d+)/
                begins = $1.to_i
                ends = $2.to_i
                # The chromosome number is indicated. The position refers to the chromosome
                gff += "Chr#{chr_number}\tAssignment3\t#{feature.feature}\t#{chr_begin+begins-1}\t#{chr_begin+ends-1}\t.\t+\t.\tgeneID=#{gene};repeat_motif=#{feature.assoc["repeat_motif"]};#{feature.assoc["note"]}\n"
            when /^complement\((\d+)\.\.(\d+)\)/
                begins = $1.to_i
                ends = $2.to_i
                gff += "Chr#{chr_number}\tAssignment3\t#{feature.feature}\t#{chr_begin+begins-1}\t#{chr_begin+ends-1}\t.\t-\t.\tgeneID=#{gene};repeat_motif=#{feature.assoc["repeat_motif"]};#{feature.assoc["note"]}\n"
            end
        end
    end
end

record = Bio::GFF::GFF3.new(gff) unless gff.nil?
# A new GFF3 file with the full chromosome coordinates is generated
gff_file = File.open("CTTCTT_chromosomes.gff3", "w")
gff_file.write("#{record.to_s}")
gff_file.close
puts "GFF3 file generated"
