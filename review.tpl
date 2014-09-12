<div itemprop="review" itemscope itemtype="http://schema.org/Review">
	<div class="row">
		<div class="col-md-2">
			<h2>{{ review.occupancy.listing.ballot_season.year }}
				% if review.rating is not None:
					<small itemprop="reviewRating" itemscope itemtype="http://schema.org/Rating">
						<span itemprop="ratingValue">{{ review.rating }}</span><!--
						-->/<span itemprop="bestRating">10</span>
					</small>
				% end
			</h2>
			% if review.occupancy.resident:
				<a itemprop="author" href="mailto:{{review.occupancy.resident.crsid}}@cam.ac.uk">
					{{review.occupancy.resident.name}}
				</a>
			% end
		</div>
		<div class="col-xs-1 visible-sm visible-xs"></div>
		% if review.sections:
			<div class="col-md-4 col-xs-11" style="padding-top: 7px">
				% for section in review.sections:
					% if section.heading.is_summary:
						<h3>
							% if "Best" in section.heading.name:
								<span class="text-success glyphicon glyphicon-thumbs-up pull-left" style="margin-left: -30px"></span>
							% elif "Worst" in section.heading.name:
								<span class="text-danger glyphicon glyphicon-thumbs-down pull-left" style="margin-left: -30px"></span>
							% else:
								<span class="glyphicon glyphicon-align-left pull-left" style="margin-left: -30px"></span>
							% end
							{{ section.heading.name }}
						</h3>
						{{! section.html_content }}
					% end
				% end
			</div>
			<div class="col-xs-1 visible-xs"></div>
			<div class="col-md-6 col-sm-12 col-xs-11" style="margin-top: 33px">
				<dl class="dl-horizontal">
					% for section in review.sections:
						% if not section.heading.is_summary:
							<dt>{{ section.heading.name }}</dt>
							<dd>{{! section.html_content }}</dd>
						% end
					% end
				</dl>
				<div class="text-right"><small class="text-muted text-right">{{ review.published_at }}</small></div>
			</div>
		% end
	</div>
</div>
