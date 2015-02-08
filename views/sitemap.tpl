% import database.orm as m
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
	<url>
		<loc>http://roompicks.caiusjcr.co.uk/</loc>
		<priority>1</priority>
	</url>
	<url>
		<loc>http://roompicks.caiusjcr.co.uk/rooms</loc>
		<priority>0.4</priority>
	</url>
	<url>
		<loc>http://roompicks.caiusjcr.co.uk/places</loc>
		<priority>0.4</priority>
	</url>

	% for c in db.query(m.Cluster).filter(m.Cluster.id != 1):
		<url>
			<loc>http://roompicks.caiusjcr.co.uk{{ url_for(c) }}</loc>
			<priority>1</priority>
		</url>
	% end

	% for r in db.query(m.Room):
		<url>
			<loc>http://roompicks.caiusjcr.co.uk/rooms/{{ r.id }}</loc>
			<priority>0.8</priority>

			% for l in r.listings:
				% for o in l.occupancies:
					% for p in o.photos:
						<image:image>
							<image:loc>http://roompicks.caiusjcr.co.uk/photos/{{ p.id }}</image:loc>
							% if p.caption:
								<image:caption>{{ p.caption }}</image:caption>
							% end
						</image:image>
					% end
				% end
			% end
		</url>
		% for l in r.listings:
			% for o in l.occupancies:
				<url>
					<loc>http://roompicks.caiusjcr.co.uk/occupancies/{{ o.id }}</loc>
					<priority>0.4</priority>
				</url>
			% end
		% end
	% end
</urlset>
