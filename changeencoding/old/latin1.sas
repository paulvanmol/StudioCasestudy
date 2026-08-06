options encoding=wlatin1;

data customers;
    length name $50 city $50 comment $100;

    name    = "André";
    city    = "Malmö";
    comment = "Café customer";
    output;

    name    = "François";
    city    = "Montréal";
    comment = "Crème brûlée";
    output;

    name    = "José";
    city    = "Bogotá";
    comment = "Mañana review";
    output;
run;
