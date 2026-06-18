package main

type MainPicture struct {
	Medium string `json:"medium"`
	Large  string `json:"large"`
}
type Node struct {
	Id          int         `json:"id"`
	Title       string      `json:"title"`
	MainPicture MainPicture `json:"main_picture"`
}

type AData struct {
	Nodes Node `json:"node"`
}

type GetAnimeListResult struct {
	Data []AData `json:"data"`
}
type Genres struct {
	Id   int    `json:"id"`
	Name string `json:"name"`
}
type AlternativeTitles struct {
	Synonyms []string `json:"synonyms"`
	En       string   `json:"en"`
	Ja       string   `json:"ja"`
}

type StartSeason struct {
	Year   int    `json:"year"`
	Season string `json:"season"`
}
type Brdodcast struct {
	DayOfTheWeek string `json:"day_of_the_week"`
	StartTime    string `json:"start_time"`
}
type RelatedAnime struct {
	Node                  Node   `json:"node"`
	RelationType          string `json:"relation_type"`
	RelationTypeFormatted string `json:"relation_type_formatted"`
}

type Studio struct {
	Id   int    `json:"id"`
	Name string `json:"name"`
}
type Picture struct {
	Medium string `json:"medium"`
	Large  string `json:"large"`
}
type MyListStatus struct {
	Status             string `json:"status"`
	Score              int    `json:"score"`
	NumEpisodesWatched int    `json:"num_episodes_watched"`
	IsRewatching       bool   `json:"is_rewatching"`
	UpdatedAt          string `json:"updated_at"`
}
type StatisticsStatus struct {
	Watching    string `json:"watching"`
	Completed   string `json:"completed"`
	OnHold      string `json:"on_hold"`
	Dropped     string `json:"dropped"`
	PlanToWatch string `json:"plan_to_watch"`
}
type Statistics struct {
	Status       StatisticsStatus `json:"status"`
	NumListUsers int              `json:"num_list_users"`
}
type Recommendation struct {
	Node               Node `json:"node"`
	NumRecommendations int  `json:"num_recommendations"`
}

type GetAnimeDetailResult struct {
	Id                     int               `json:"id"`
	Title                  string            `json:"title"`
	MainPicture            MainPicture       `json:"main_picture"`
	AlternativeTitles      AlternativeTitles `json:"alternative_titles"`
	StartDate              string            `json:"start_date"`
	EndDate                string            `json:"end_date"`
	Synopsis               string            `json:"synopsis"`
	Mean                   float64           `json:"mean"`
	Rank                   int               `json:"rank"`
	Popularity             int               `json:"popularity"`
	NumListUsers           int               `json:"num_list_users"`
	NumScoringUsers        int               `json:"num_scoring_users"`
	Nsfw                   string            `json:"nsfw"`
	CreatedAt              string            `json:"created_at"`
	UpdatedAt              string            `json:"updated_at"`
	MediaType              string            `json:"media_type"`
	Status                 string            `json:"status"`
	Genres                 []Genres          `json:"genres"`
	MyListStatus           MyListStatus      `json:"my_list_status"`
	NumEpisodes            int               `json:"num_episodes"`
	StartSeason            StartSeason       `json:"start_season"`
	Broadcast              Brdodcast         `json:"broadcast"`
	Source                 string            `json:"source"`
	AverageEpisodeDuration int               `json:"average_episode_duration"`
	Rating                 string            `json:"rating"`
	Pictures               []Picture         `json:"pictures"`
	Background             string            `json:"background"`
	RelatedAnime           []RelatedAnime    `json:"related_anime"`
	RelatedManga           []interface{}     `json:"related_manga"`
	Recommendations        []Recommendation  `json:"recommendations"`
	Studios                []Studio          `json:"studios"`
	Statistics             Statistics        `json:"statistics"`
}
