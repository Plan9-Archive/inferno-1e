HTML: module
{
	PATH:		con "/dis/lib/html.dis";

	Lex: adt
	{
		tag:		int;
		text:		string;	# text in Data, attribute text in tag
		attr:		list of Attr;
	};

	Attr: adt
	{
		name:	string;
		value:	string;
	};

	Notfound: con -1;
	# sorted in lexical order; used as array indices
	Ta, Taddress, Tapplet, Tarea, Tatt_footer, Tb,
		Tbase, Tbasefont, Tbig, Tblink, Tblockquote, Tbody,
		Tbq, Tbr, Tcaption, Tcenter, Tcite, Tcode, Tcol, Tcolgroup,
		Tdd, Tdfn, Tdir, Tdiv, Tdl, Tdt, Tem,
		Tfont, Tform, Th1, Th2, Th3, Th4, Th5, Th6, Thead, Thr, Thtml, Ti, Timg,
		Tinput, Tisindex, Titem, Tkbd, Tli, Tlink, Tmap, Tmenu,
		Tmeta, Tol, Toption, Tp, Tparam, Tpre,
		Tq, Tstrike, Tsamp, Tscript, Tselect, Tsmall, Tstrong,
		Tstyle, Tsub, Tsup, Tt, Ttable, Ttbody, Ttd, Ttextarea, Ttextflow, Ttfoot, Tth,
		Tthead, Ttitle, Ttr, Ttt, Tu, Tul, Tvar
			: con iota;
	RBRA: con 1000;
	Data: con 2000;

	lex:		fn(b: array of byte, keepnls: int): array of ref Lex;
	attrvalue:	fn(attr: list of Attr, name: string): (int, string);
	globalattr:	fn(html: array of ref Lex, tag: int, attr: string): (int, string);
	isbreak:	fn(h: array of ref Lex, i: int): int;
	lex2string:	fn(l: ref Lex): string;
};
