implement Mv;

include "sys.m";
	sys: Sys;
	stderr: ref Sys->FD;

include "draw.m";
	draw: Draw;

include "string.m";
	str : String;


Mv : module 
{
	init: fn(ctxt: ref Draw->Context, argv: list of string);
};

init(nil: ref Draw->Context, argv: list of string)
{
	sys = load Sys Sys->PATH;
	str = load String String->PATH;

	stderr = sys->fildes(2);

	dirto, dirfrom: Sys->Dir;
	todir, toelem: string;
	if(len argv<3) {
		sys->fprint(stderr, "usage: mv fromfile tofile\n");
		sys->fprint(stderr, "       mv fromfile ... todir\n");
		exit;
	}
	argv = tl argv;
	arr := array[len argv] of string;
	for (i:=0; argv!=nil;i++){
		arr[i]= hd argv;
		argv = tl argv;
	}
	(i,dirto)=sys->stat(arr[len arr-1]);
	if(i >= 0 && (dirto.mode&Sys->CHDIR)){
		(i,dirfrom)=sys->stat(arr[0]);
		if(len arr == 2 && i >= 0 && (dirfrom.mode&Sys->CHDIR))
			(todir,toelem)=split(arr[len arr-1]);
		else{
			todir = arr[len arr -1];
			toelem = "";	# toelem will be fromelem 
		}
	}else
		(todir,toelem)=split(arr[len arr-1]);
	if(len arr > 2  && toelem != nil){
		sys->fprint(stderr, "mv: %s not a directory\n", arr[len arr-1]);
		exit;
	}
	for(i=0; i < len arr-1; i++)
		if (mv(arr[i], todir, toelem) < 0)
			exit;
	exit;
}

mv(from,todir,toelem : string): int
{
	(i,dirb):=sys->stat(from);
	if(i != 0) {
		sys->fprint(stderr, "mv: can't stat %s: \n", from);
		return -1;
	}
	(fromdir,fromelem):=split(from);
	fromname:= fromdir+fromelem;
	if(toelem == nil){
		if (todir[len todir-1]!='/')
			todir[len todir]='/';
		toelem = fromelem;
	}
	i = len toelem;
	if(i==0){
		sys->fprint(stderr, "mv: null last name element moving %s\n", fromname);
		return -1;
	}
	toname:=todir+toelem;
	if(samefile(fromdir, todir)){
		if(samefile(fromname, toname)){
			sys->fprint(stderr, "mv: %s and %s are the same\n",fromname,toname);
			return -1;
		}
		(j,dirt):=sys->stat(toname);
		if(j == 0)
			hardremove(toname);
		dirb.name=toelem;
		if(sys->wstat(fromname,dirb) >= 0)
			return 0;
		if(dirb.mode&Sys->CHDIR){
			sys->fprint(stderr, "mv: can't rename directory %s: \n", fromname);
			return -1;
		}
	}
	# Renaming won't work --- have to copy
	if(dirb.mode&Sys->CHDIR){
		sys->fprint(stderr, "mv: %s is a directory, not copied to %s\n", fromname, toname);
		return -1;
	}
	fdf := sys->open(fromname, Sys->OREAD);
	if(fdf==nil){
		sys->fprint(stderr, "mv: can't open %s: \n", fromname);
		return -1;
	}
	(j,dirt):=sys->stat(toname);
	fdt := sys->create(toname, Sys->OWRITE, dirb.mode);
	if(fdt == nil){
		sys->fprint(stderr, "mv: can't create %s: \n", toname);
		return -1;
	}
	if ((stat := copy1(fdf, fdt, fromname, toname)) != -1)
		fdf = nil;	# temp bug: sometimes can't remove open file
		if (sys->remove(fromname) < 0) {
			sys->fprint(stderr, "mv: can't remove %s \n", fromname);
			return -1;
		}
	return stat;
}


copy1(fdf, fdt : ref Sys->FD,from, fto : string): int
{
	n : int;
	buf:=array[8192] of byte;
	for(;;) {
		n = sys->read(fdf, buf, len buf);
		if (n<=0)
			break;
		n1 := sys->write(fdt, buf, n);
		if(n1 != n) {
			sys->fprint(stderr, "mv: error writing %s:\n", fto);
			return -1;
		}
	}
	if(n < 0) {
		sys->fprint(stderr, "mv: error reading %s:\n", from);
		return -1;
	}
	return 0;
}

split(name : string): (string,string)
{
	(d,t) := str->splitr(name, "/");
	if(d!=nil)
		return(d,t);
	else if(name=="..")
		return("../",".");
	else
		return("./",name);
}

samefile(a,b : string): int
{
	if(a==b) 
		return 1;
	(i,da):=sys->stat(a);
	(j,db):=sys->stat(b);
	if(i < 0 || j < 0)
		return 0;
	i= (da.qid.path==db.qid.path && da.qid.vers==db.qid.vers &&
		da.dev==db.dev && da.dtype==db.dtype);
	return i;
}


hardremove(a: string)
{
	if(sys->remove(a) == -1){
		sys->fprint(stderr, "mv: can't remove %s\n", a);
		exit;
	}
	do; while(sys->remove(a) != -1);
}
