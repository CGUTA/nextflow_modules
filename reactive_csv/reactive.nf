
params.new="a.csv"
params.cache_dir="cache"
Channel
    .fromPath("${params.cache_dir}/${params.new}")
    .splitCsv(header:true)
    .map{ row-> tuple(row.tag, row.frequencies) }
    .set { tags }

Channel
    .fromPath("${params.new}")
    .splitCsv(header:true)
    .map{ row-> tuple(row.tag, row.frequencies) }
    .into { tags_cache ; update}

process cache {
	echo true
	
	input:
	set tag, size, old_size from tags.join(tags_cache, remainder: true)

	output:
	val tag into out

	when:
	old_size != size || old_size == null

	"""
	echo "calculating $tag $size $old_size"
	"""

}

process update {
	echo true
	publishDir "${params.cache_dir}", mode: 'copy', overwrite: true
	
	input:
	val tags from out.toList()
	file updated_file from file("${params.new}")

	output:
	file updated_file

	when:
	tags.size != 0

	"""
	echo updating $tags $updated_file
	cp $updated_file b.csv
	cat $updated_file

	"""

}