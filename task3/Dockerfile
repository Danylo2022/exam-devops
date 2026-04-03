# Беру легку версію пайтона, щоб образ не важив гігабайти
FROM python:3.11-slim

# Робоча папка всередині контейнера
WORKDIR /app

# Копіюю список бібліотек
COPY requirements.txt .

# Встановлюю Flask
RUN pip install --no-cache-dir -r requirements.txt

# Закидаю код самого додатка
COPY app.py .

# Відкриваю порт 5000 для світу
EXPOSE 5000

# Запуск!
CMD ["python", "app.py"]