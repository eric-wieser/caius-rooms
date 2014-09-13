import db
import orm
import os

# os.remove('test.db')

db.init('dev')
orm.Base.metadata.drop_all(db.engine)
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
	orm.ReviewHeading(name="Best Features", is_summary=True),
	orm.ReviewHeading(name="Worst Features", is_summary=True),
	orm.ReviewHeading(name="General Comments", is_summary=True,
		prompt="Number of sockets, if recently redecorated, special features, comments on location")
]

for i, h in enumerate(headings):
	h.position = i
	session.add(h)
	session.commit()

groupings = orm.Cluster(name="Root", children=[
	orm.Cluster(name="Old courts", children=[
		orm.Cluster(name="Caius Court",     type="building", latitude=52.2062, longitude=0.117019),
		orm.Cluster(name="Tree Court",      type="building", latitude=52.2059, longitude=0.116987),
		orm.Cluster(name="Gonville Court",  type="building", latitude=52.206, longitude=0.117567)
	]),
	orm.Cluster(name="St Michael's Court",  type="building", latitude=52.206, longitude=0.118629),
	orm.Cluster(name="St Mary's Court",     type="building", latitude=52.2057, longitude=0.118157),

	orm.Cluster(name="West Road site", children=[
		orm.Cluster(name="Springfield",     type="building", latitude=52.2007, longitude=0.112197),
		orm.Cluster(name="Harvey Court",    type="building", latitude=52.2024, longitude=0.110807),
		orm.Cluster(name="K Block",         type="building", latitude=52.2027, longitude=0.111505),
		orm.Cluster(name="Stephen Hawking Building"),
	]),

	orm.Cluster(name="Mortimer Road", type="road", children=[
		orm.Cluster(name="1",               type="building", latitude=52.2018, longitude=0.132383),
		orm.Cluster(name="2",               type="building", latitude=52.2017, longitude=0.132329),
		orm.Cluster(name="3",               type="building", latitude=52.2016, longitude=0.132233),
		orm.Cluster(name="4",               type="building", latitude=52.2016, longitude=0.132169),
		orm.Cluster(name="5",               type="building", latitude=52.2014, longitude=0.132072),
		orm.Cluster(name="6",               type="building", latitude=52.2014, longitude=0.132008),
		orm.Cluster(name="7",               type="building", latitude=52.2013, longitude=0.131922),
		orm.Cluster(name="8",               type="building", latitude=52.2012, longitude=0.131868)
	]),

	orm.Cluster(name="Green Street", type="road", children=[
		orm.Cluster(name="27",              type="building", latitude=52.2065, longitude=0.118857),
		orm.Cluster(name="28A",             type="building", latitude=52.2065, longitude=0.119082),
		orm.Cluster(name="37",              type="building", latitude=52.2067, longitude=0.119597)
	]),

	orm.Cluster(name="Rose Crescent", type="road", children=[
		orm.Cluster(name="1A",              type="building", latitude=52.2063, longitude=0.118154),
		orm.Cluster(name="4",               type="building", latitude=52.2063, longitude=0.118661)
	]),

	orm.Cluster(name="Gresham Road", type="road", children=[
		orm.Cluster(name="5",               type="building", latitude=52.1996, longitude=0.130012),
		orm.Cluster(name="6",               type="building", latitude=52.1996, longitude=0.130012)
	]),

	orm.Cluster(name="Harvey Road", type="road", children=[
		orm.Cluster(name="5",               type="building", latitude=52.1989, longitude=0.130087),
		orm.Cluster(name="6",               type="building", latitude=52.1989, longitude=0.130248)
	]),

	orm.Cluster(name="St Pauls Road", type="road", children=[
		orm.Cluster(name="3",               type="building", latitude=52.1985, longitude=0.130913),
		orm.Cluster(name="4",               type="building", latitude=52.1986, longitude=0.131063)
	]),

	orm.Cluster(name="35-37 Chesterton Road", type="building", latitude=52.2129, longitude=0.119669),
	orm.Cluster(name="43 Glisson Road",       type="building", latitude=52.198, longitude=0.1325)
])

session.add(groupings)
session.commit()

