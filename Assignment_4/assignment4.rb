require 'bio' # Classes required

#The next two lines were neccessary to create de databases:
#makeblastdb -in pep.fa -dbtype 'prot' -out PROTPOMBE
#makeblastdb -in TAIR10_seq_20110103_representative_gene_model_updated -dbtype 'nucl' -out GENARA

# A minimum evalue of 1-e6 was set and soft filtering (with -F the algorithm finds more matches, so it probably changes to soft filtering) was performed
# See reference tocheck the paper this information was provided
pombe_proteome = Bio::Blast.local('blastx', 'PROTPOMBE', '-e 1e-6 -F') #Blastx algorithm for searching in S. pombe proteome
ara_genome = Bio::Blast.local('tblastn', 'GENARA', '-e 1e-6 -F') #Tblastn algorithm for searching in A. thaliana genome

# An array for each FASTA file is created, separated by '>' and deleting empty values
file_at = File.open('TAIR10_seq_20110103_representative_gene_model_updated', 'r')
file_sp = File.open('pep.fa', 'r')
genes_at = file_at.read.split('>')
genes_at.reject! {|gene| gene.empty?}
prots_sp = file_sp.read.split('>')
prots_sp.reject! {|prot| prot.empty?}
file_at.close
file_sp.close

# A'>' is added at the beginning of each element of the array to have the correct FASTA format
# Spaces at the end of each FASTA are also deleted
# This is done for both arrays
genes_at.each do |gene|
    next if gene==nil
    gene.prepend('>')
    gene.strip!
end
prots_sp.each do |prot|
    next if prot==nil 
    prot.prepend('>')
    prot.strip!
end

# A txt file is created to save the positive results of the reciprocal BLAST
file = File.open("Orthologue_Report.txt", "w")
i = 0 # For counting the loop
prots_sp.each do |prot| # Each protein of the S. pombe proteome is blasted again the genome of A. thaliana
    puts "Searching possible orthologue...(#{i+1}/#{prots_sp.length+1})"
    i += 1
    prot_fasta = Bio::FastaFormat.new(prot) # Create FASTA object
    report = ara_genome.query(prot_fasta)
    unless report.hits[0]==nil # To make sure report has hits
        top_hit = report.hits[0] # Top hit is saved
        gene_fasta = Bio::FastaFormat.new(genes_at[top_hit.target_id.to_i]) # FASTA objet is created from top hit using its index
        report2 = pombe_proteome.query(gene_fasta) # Blast of the top hit againts the proteome of S. pombe
        unless report2.hits[0]==nil # To make sure report has hits
            top_hit2 = report2.hits[0]
            comparison_fasta = Bio::FastaFormat.new(prots_sp[top_hit2.target_id.to_i]) # FASTA object is created from top hit of the reciprocal BLAST
        end
    end
    # If the result of the second blast is the initial protein of S. pombe, their entry_id are also the same, so they are compared
    # and saved in the report as orthologue candidates. If not, a message is printed
    if comparison_fasta && prot_fasta.entry_id == comparison_fasta.entry_id
        puts "Orthologue candidates: A. thaliana #{gene_fasta.entry_id} and S. pombe #{prot_fasta.entry_id}"
        file.write("Orthologue candidates: A. thaliana #{gene_fasta.entry_id} and S. pombe #{prot_fasta.entry_id}\n")
    else
        puts "No orthologue candidates"
    end
end
file.write("References: Moreno-Hagelsieb, G., & Latimer, K. (2008). Choosing BLAST options for better detection of orthologs as reciprocal best hits. Bioinformatics, 24(3), 319-324.\n")
file.close # To close the report