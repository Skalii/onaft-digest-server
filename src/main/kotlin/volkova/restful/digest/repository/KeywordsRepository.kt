package volkova.restful.digest.repository


import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.repository.Repository as MyRepository
import org.springframework.stereotype.Repository

import volkova.restful.digest.entity.Keyword


@Repository
interface KeywordsRepository : MyRepository<Keyword, Int> {

    @Query(value = """select (keyword_record(
                          cast_int(:id_keyword),
                          cast_text(:word)
                      )).*""",
            nativeQuery = true)
    fun find(
            @Param("id_keyword") idKeyword: Int? = null,
            @Param("word") word: String? = null
    ): Keyword

    @Query(value = """select (keyword_record(all_record => true)).*""",
            nativeQuery = true)
    fun findAll(): MutableList<Keyword>

    @Query(value = """select (keyword_insert(
                          cast_text(:#{#keyword.word})
                      )).*""",
            nativeQuery = true)
    fun add(@Param("keyword") newKeyword: Keyword): Keyword

    @Query(value = """select (keyword_update(
                          cast_text(:#{#keyword.word}),
                          cast_int(:#{#keyword.idKeyword})
                      )).*""",
            nativeQuery = true)
    fun set(@Param("keyword") newKeyword: Keyword): Keyword

    @Query(value = """select (keyword_delete(cast_int(:id_keyword))).*""",
            nativeQuery = true)
    fun remove(@Param("id_keyword") idKeyword: Int): Keyword

}