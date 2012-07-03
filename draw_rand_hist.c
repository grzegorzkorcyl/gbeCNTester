{
	FILE *fp = fopen("c:\\Users\\Grzegorz\\Desktop\\Simulations\\CNTester\\main.log","r");
	UInt_t values;

	TH1F* hist = new TH1F("hist", "hist", 50000, 0, 50000);
	TH1F* hist2 = new TH1F("hist2", "hist2", 1000, 0, 1000);


	char line[10];
	int ctr = 0;
	while (fgets(&line,10,fp)) {
      	  sscanf(&line,"%d",&values);
	  hist->Fill(ctr, values);
	  hist2->Fill(values);

	  ctr++;

	}

	fclose(fp);

	hist2->Draw("values");

	return 0;
}