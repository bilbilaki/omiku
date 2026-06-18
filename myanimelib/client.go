package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

// This variable is populated exclusively at compile time via the linker
var BuildTimeClientID string

const BaseURL = "https://api.myanimelist.net/v2"

type MALGuestClient struct {
	HTTPClient *http.Client
}

func NewMALGuestClient() *MALGuestClient {
	return &MALGuestClient{
		HTTPClient: &http.Client{Timeout: 50 * time.Second},
	}
}

func (c *MALGuestClient) SearchAnime(query string, limit int) (GetAnimeListResult, error) {
		var result GetAnimeListResult

	// Fallback verification 
	if BuildTimeClientID == "" {
		return result, fmt.Errorf("critical error: MAL Client ID was not injected at build time")
	}

	endpoint := fmt.Sprintf("%s/anime", BaseURL)
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
	endpoint := fmt.Sprintf("%s/anime/%d", BaseURL, animeID)
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