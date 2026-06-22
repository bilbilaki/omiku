package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// This variable is populated exclusively at compile time via the linker
var BuildTimeClientID string

const MYAnimeListBaseUrl = "https://api.myanimelist.net/v2"
const ANIListBaseUrl = "https://graphql.anilist.co"
type MALGuestClient struct {
	HTTPClient *http.Client
}
type GraphQLRequest struct {
	Query     string                 `json:"query"`
	Variables map[string]interface{} `json:"variables"`
}

func NewMALGuestClient() *MALGuestClient {
	return &MALGuestClient{
		HTTPClient: &http.Client{Timeout: 50 * time.Second},
	}
}

func (c *MALGuestClient) SearchMangaAniList(queryi string)(GetMangaResult, error){
	var result GetMangaResult

	query := `
		query Media($type: MediaType, $search: String) {
			Media(type: $type, search: $search) {
				id
				description
				coverImage {
					medium
					large
					extraLarge
					color
				}
				chapters
				bannerImage
				genres
				hashtag
				title {
					english
					romaji
					native
				}
			}
		}
	`

	// 2. Define your variables
	variables := map[string]interface{}{
		"search": queryi,
		"type":   "MANGA",
	}

	// 3. Combine them into the request payload struct
	payload := GraphQLRequest{
		Query:     query,
		Variables: variables,
	}

	// 4. Convert the struct into JSON bytes
	jsonData, err := json.Marshal(payload)
	if err != nil {
		fmt.Printf("Error marshaling JSON: %v\n", err)
		return result , err
	}

	// 5. Create the HTTP POST request
	req, err := http.NewRequest("POST", ANIListBaseUrl, bytes.NewBuffer(jsonData))
	if err != nil {
		fmt.Printf("Error creating request: %v\n", err)
		return result,err
	}

	// 6. Set the required headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")

	// 7. Execute the request
	client := c.HTTPClient
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("Error making request: %v\n", err)
		return result , err
	}
	defer resp.Body.Close()

	// 8. Read and print the response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Printf("Error reading response body: %v\n", err)
		return result, err
	}
	err = json.Unmarshal(body,result)
if err!=nil {
	return result, err
}

	fmt.Println("Response Status:", resp.Status)
	fmt.Println("Response Body:\n", string(body))
	return  result,nil

}

func (c *MALGuestClient) SearchAnime(query string, limit int) (GetAnimeListResult, error) {
		var result GetAnimeListResult

	// Fallback verification 
	if BuildTimeClientID == "" {
		return result, fmt.Errorf("critical error: MAL Client ID was not injected at build time")
	}

	endpoint := fmt.Sprintf("%s/anime", MYAnimeListBaseUrl)
	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return result, err
	}

	q := req.URL.Query()
	q.Set("q", query)
	q.Set("limit", fmt.Sprintf("%d", limit))
	q.Set("fields", "id,title,main_picture,mean") 
	req.URL.RawQuery = q.Encode()

	// Use the baked-in variable directly
	req.Header.Set("X-MAL-CLIENT-ID", BuildTimeClientID)
	req.Header.Set("Accept", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return result, err
	}
	defer resp.Body.Close()
	var res json.RawMessage

		if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
return result, err
	}
	if err:= json.Unmarshal(res,&result ); err!=nil{
		return result, err
	}

	return result, nil
}

// Add this method to client.go

func (c *MALGuestClient) GetAnimeDetail(animeID int) (GetAnimeDetailResult, error) {
	var result GetAnimeDetailResult

	if BuildTimeClientID == "" {
		return result, fmt.Errorf("critical error: MAL Client ID was not injected at build time")
	}

	// Endpoint structure: https://api.myanimelist.net/v2/anime/{id}
	endpoint := fmt.Sprintf("%s/anime/%d", MYAnimeListBaseUrl, animeID)
	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return result, err
	}

	// Requesting all metadata fields mapped in your GetAnimeDetailResult struct
	q := req.URL.Query()
	q.Set("fields", "id,title,main_picture,alternative_titles,start_date,end_date,synopsis,mean,rank,popularity,num_list_users,num_scoring_users,nsfw,created_at,updated_at,media_type,status,genres,num_episodes,start_season,broadcast,source,average_episode_duration,rating,pictures,background,related_anime,recommendations,studios,statistics")
	req.URL.RawQuery = q.Encode()

	req.Header.Set("X-MAL-CLIENT-ID", BuildTimeClientID)
	req.Header.Set("Accept", "application/json")

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return result, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return result, fmt.Errorf("MAL detail API returned status: %s", resp.Status)
	}

	// Decode straight into your destination struct safely via pointer
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return result, err
	}

	return result, nil
}