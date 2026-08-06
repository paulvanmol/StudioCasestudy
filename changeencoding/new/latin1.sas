options encoding=wlatin1;

data customers;
    length name $50 city $50 comment $100;

    name    = "André";
    city    = "Malmö";
    comment = "Café customer";
    output;

    name    = "François";
    city    = "Montréal";
    comment = "Crčme brűlée";
    output;

    name    = "José";
    city    = "Bogotá";
    comment = "Mańana review";
    output;
run;
