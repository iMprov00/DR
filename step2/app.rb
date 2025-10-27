require 'telegram/bot'

token = '8380813420:AAE6iqxrLcpdFZbEKhjccr28rzVKisqJ1nc'

# Хэш для хранения прогресса пользователей
user_progress = {}

# Загадки и варианты ответов
RIDDLES = [
  {
    question: "Очень странный почтальон -\nНе маггл, не волшебник он\nХранить умеет все секреты\nНесёт посылку на край света.\nКрылат, и смел, и зорок он\nКто же этот почтальон?",
    options: ["Феникс", "Сова", "Дементор", "Гиппогриф"],
    correct: 1
  },
  {
    question: "Тайная школа на замок похожа.\nУчат в той школе детей колдовать.\nТуда не проникнет случайный прохожий.\nСкажите-ка дружно, как школу ту звать?",
    options: ["Дурмстранг", "Хогвартс", "Шармбатон", "Махутокор"],
    correct: 1
  },
  {
    question: "Шрам в виде молнии на лбу.\nТот мальчик может колдовать.\nТы помоги скорей ему,\nНапомни, как мальчишку звать?",
    options: ["Рон Уизли", "Гарри Поттер", "Невилл Лонгботтом", "Драко Малфой"],
    correct: 1
  },
  {
    question: "В лиловой мантии старик,\nК лимонным долькам он привык.",
    options: ["Профессор Снейп", "Дамблдор", "Профессор Люпин", "Корнелиус Фадж"],
    correct: 1
  },
  {
    question: "Он не птица и не зверь,\nНо летать умеет,\nЛюбит вежливых людей.\nОтгадай скорее,\nЧто это за существо?\nНазови быстрей его!",
    options: ["Василиск", "Гиппогриф", "Тролль", "Фестрал"],
    correct: 1
  }
]

# Определяем методы перед основным кодом
def send_riddle(bot, chat_id, riddle_index)
  riddle = RIDDLES[riddle_index]
  
  buttons = riddle[:options].map.with_index do |option, index|
    Telegram::Bot::Types::InlineKeyboardButton.new(
      text: option,
      callback_data: "riddle_#{riddle_index}_#{index}"
    )
  end.each_slice(2).to_a # Разбиваем на ряды по 2 кнопки

  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
  
  bot.api.send_message(
    chat_id: chat_id,
    text: "Загадка #{riddle_index + 1} из #{RIDDLES.size}:\n\n#{riddle[:question]}",
    reply_markup: markup
  )
end

def handle_riddle_answer(bot, message, user_progress)
  data_parts = message.data.split('_')
  riddle_index = data_parts[1].to_i
  answer_index = data_parts[2].to_i
  
  user_id = message.from.id
  riddle = RIDDLES[riddle_index]
  
  if answer_index == riddle[:correct]
    # Правильный ответ
    bot.api.answer_callback_query(callback_query_id: message.id, text: "Верно! ✅")
    
    sleep(1)
    
    if riddle_index + 1 < RIDDLES.size
      # Следующая загадка
      user_progress[user_id] ||= {}
      user_progress[user_id][:current_riddle] = riddle_index + 1
      bot.api.send_message(
        chat_id: user_id,
        text: "Отлично! Эта часть заклинания на месте... 🪄"
      )
      sleep(2)
      send_riddle(bot, user_id, riddle_index + 1)
    else
      # Все загадки решены
      bot.api.send_message(
        chat_id: user_id,
        text: "Потрясающе! Все части заклинания собраны! ✨"
      )
      
      sleep(3)
      
      # Люпин произносит заклинание
      bot.api.send_message(
        chat_id: user_id,
        text: "*Релусио Остиум!* - произносит Люпин, направляя палочку на дверь..."
      )
      
      sleep(2)
      
      # Дверь открывается (гифка)
      bot.api.send_animation(
        chat_id: user_id,
        animation: Faraday::UploadIO.new('door_open.gif', 'image/gif')
      )
      
      sleep(2)
      
      # Финальное сообщение со ссылкой
      bot.api.send_message(
        chat_id: user_id,
        text: "Дверь открыта! Спасибо тебе огромное, Стеша! Без тебя я бы не справился.\n\nТеперь тебе предстоит встретиться с Северусом Снейпом... Но чтобы его найти, тебе нужна карта! Поищи её в своем шкавчике, который возле магической TV скрижали.",
        parse_mode: 'Markdown'
      )
      
      # Очищаем прогресс
      user_progress.delete(user_id)
    end
  else
    # Неправильный ответ
    wrong_answer_messages = [
      "Почти, но не совсем... Попробуй ещё раз!",
      "Интересная мысль, но присмотрись получше...",
      "Хм, нет, это не то. Давай подумаем ещё...",
      "Ошибиться может каждый! Попробуй снова."
    ]
    
    bot.api.answer_callback_query(
      callback_query_id: message.id,
      text: wrong_answer_messages.sample
    )
  end
end

# Основной код бота
Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        # Приветствие от Люпина
        bot.api.send_animation(
          chat_id: message.chat.id,
          animation: Faraday::UploadIO.new('hello.gif', 'image/gif')
        )

        bot.api.send_message(
          chat_id: message.chat.id,
          text: "А, Стеша! Приветствую. Я слышал, Хагрид тебя направил. Кажется, ты немного взволнована..."
        )
        
        sleep(2)
        
        # Шоколад
        bot.api.send_photo(
          chat_id: message.chat.id,
          photo: Faraday::UploadIO.new('chocolate.jpg', 'image/jpg'),
          caption: "Вот, возьми шоколадку. Отлично помогает против дементоров... и простой тревоги тоже."
        )
        
        sleep(3)
        
        # Объяснение задачи
        bot.api.send_photo(
          chat_id: message.chat.id,
          photo: Faraday::UploadIO.new('door.jpg', 'image/jpg'),
          caption: "Видишь эту заколдованную дверь? Чтобы открыть её, нужно составить специальное заклинание.\n\nЯ приготовил несколько загадок - каждая разгадка станет частью заклинания. Поможешь мне?"
        )

        sleep(4)
        
        # Начинаем первую загадку
        user_progress[message.chat.id] = { current_riddle: 0 }
        send_riddle(bot, message.chat.id, 0)

      when '/help'
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Просто выбирай вариант ответа, который считаешь правильным. Если ошибёшься - ничего страшного, попробуешь снова!"
        )
      end

    when Telegram::Bot::Types::CallbackQuery
      if message.data.start_with?('riddle_')
        handle_riddle_answer(bot, message, user_progress)
      end
    end
  end
end