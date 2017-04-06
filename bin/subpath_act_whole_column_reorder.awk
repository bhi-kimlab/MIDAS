BEGIN{
	FS=OFS=",";
	n=split(sample_order, sample_order_arr, ",");
}
{
	for(i=1;i<=n;i++){
		printf "%s%s", $(sample_order_arr[i]), OFS;
	}
	printf "%s%s", $(NF), "\n";
}

	
