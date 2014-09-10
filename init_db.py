import db
import orm

db.init('dev')
orm.Base.metadata.create_all(db.engine)

session = db.Session()

headings = [
	orm.ReviewHeading(name="Noise"),
	orm.ReviewHeading(name="Natural lighting"),
	orm.ReviewHeading(name="Heating"),
	orm.ReviewHeading(name="Kitchen",
		prompt="How many do you share with? How far is it from your room? Details on size/facilities"),
	orm.ReviewHeading(name="Bathroom",
		prompt="How many people do you share with? How far is it from your room? Does it have a bath?"),
	orm.ReviewHeading(name="Furniture",
		prompt="What furniture comes with the room? What electrical lighting is provided?"),
	orm.ReviewHeading(name="Best Features"),
	orm.ReviewHeading(name="Worst Features"),
	orm.ReviewHeading(name="General Comments",
		prompt="Number of sockets, if recently redecorated, special features, comments on location")
]

for i, h in enumerate(headings):
	h.position = i
	session.add(h)
	session.commit()

groupings = orm.Cluster(name="Root", children=[
	orm.Cluster(name="Old courts", forms_name=False, children=[
		orm.Cluster(name="Caius Court",     latitude=0.117019, longitude=52.2062),
		orm.Cluster(name="Tree Court",      latitude=0.116987, longitude=52.2059),
		orm.Cluster(name="Gonville Court",  latitude=0.117567, longitude=52.206)
	]),
	orm.Cluster(name="St Michael's Court",  latitude=0.118629, longitude=52.206),
	orm.Cluster(name="St Mary's Court",     latitude=0.118157, longitude=52.2057),

	orm.Cluster(name="West Road site", forms_name=False, children=[
		orm.Cluster(name="Springfield",     latitude=0.112197, longitude=52.2007),
		orm.Cluster(name="Harvey Court",    latitude=0.110807, longitude=52.2024),
		orm.Cluster(name="K Block",         latitude=0.111505, longitude=52.2027),
		orm.Cluster(name="Stephen Hawking Building"),
	]),

	orm.Cluster(name="Mortimer Road", children=[
		orm.Cluster(name="1",               latitude=0.132383, longitude=52.2018),
		orm.Cluster(name="2",               latitude=0.132329, longitude=52.2017),
		orm.Cluster(name="3",               latitude=0.132233, longitude=52.2016),
		orm.Cluster(name="4",               latitude=0.132169, longitude=52.2016),
		orm.Cluster(name="5",               latitude=0.132072, longitude=52.2014),
		orm.Cluster(name="6",               latitude=0.132008, longitude=52.2014),
		orm.Cluster(name="7",               latitude=0.131922, longitude=52.2013),
		orm.Cluster(name="8",               latitude=0.131868, longitude=52.2012)
	]),

	orm.Cluster(name="Green Street", children=[
		orm.Cluster(name="27",              latitude=0.118857, longitude=52.2065),
		orm.Cluster(name="28A",             latitude=0.119082, longitude=52.2065),
		orm.Cluster(name="37",              latitude=0.119597, longitude=52.2067)
	]),

	orm.Cluster(name="Rose Crescent", children=[
		orm.Cluster(name="1A",              latitude=0.118154, longitude=52.2063),
		orm.Cluster(name="4",               latitude=0.118661, longitude=52.2063)
	]),

	orm.Cluster(name="Gresham Road", children=[
		orm.Cluster(name="5",               latitude=0.130012, longitude=52.1996),
		orm.Cluster(name="6",               latitude=0.130012, longitude=52.1996)
	]),

	orm.Cluster(name="Harvey Road", children=[
		orm.Cluster(name="5",               latitude=0.130087, longitude=52.1989),
		orm.Cluster(name="6",               latitude=0.130248, longitude=52.1989)
	]),

	orm.Cluster(name="St Pauls Road", children=[
		orm.Cluster(name="3",               latitude=0.130913, longitude=52.1985),
		orm.Cluster(name="4",               latitude=0.131063, longitude=52.1986)
	]),

	orm.Cluster(name="35-37 Chesterton Rd", latitude=0.119669, longitude=52.2129),
	orm.Cluster(name="43 Glisson Rd",       latitude=0.1325, longitude=52.198)
])

session.add(groupings)
session.commit()

