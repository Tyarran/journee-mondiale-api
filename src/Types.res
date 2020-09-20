type internationalDay = {
  content: option<string>,
  imageUrl: option<string>,
  title: string,
  url: string,
}

type internationalDaySummary = {
  title: string,
  url: string,
}

type daySummary = {
  date: string,
  uri: string,
  internationalDays: array<internationalDaySummary>,
}
